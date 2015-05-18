defmodule Amt do
  @moduledoc """
  Application management tool. Parses application emails sent by
  LinkedIn and creates a CSV formatted data sheet (delimited by ';').
  """

  def main(argv) do
    { parse, _, _ } = OptionParser.parse(
      argv, strict: [help: :boolean, seq: :boolean, show_pos: :boolean, path: :string])

    if parse[:path] != nil do
      if parse[:seq] do
        scan_files_sequentially(parse[:path], parse[:show_pos])
      else
        scan_files(parse[:path], parse[:show_pos])
      end |> Enum.each(fn(x) -> IO.puts(x) end)
    else
      print_help()
    end
  end


  @doc """
  Extract the data from the applicants' emails, sort the CSV records
  and print them to stdout. Emails are scanned sequentially by the same
  process.
  """
  def scan_files_sequentially(path, show_pos \\ false) do
    Path.wildcard(path <> "/*.eml")
    |> Enum.map(fn x -> scan_file(x, show_pos) end) |> Enum.sort
  end


  @doc """
  Extract the data from the applicants' emails and return a CSV record
  (where the fields are delimited by a ';').
  """
  def scan_file(path, show_pos \\ false) do
    {:ok, body} = File.read(path)
    {pos, name} = get_name(body)
    email = get_email(body)
    phone = get_phone(body)
    date = get_date(body)
    if show_pos do
      Enum.join([pos, name, email, phone, date], ";")
    else
      Enum.join([name, email, phone, date], ";")
    end
  end


  @doc """
  Extract the applicant's email address from the LinkedIn email.
  """
  def get_email(txt) do
    { :ok, rx } = Regex.compile(~S"Contact InformationEmail:\s+(\S+)", "ums")
    Regex.run(rx, txt) |> List.last
  end


  @doc """
  Extract the applicant's phone number from the LinkedIn email.
  """
  def get_phone(txt) do
    {:ok, rx } = Regex.compile(~S"Phone:\s*(\+?[\d\s]+\d)", "ums")
    case Regex.run(rx, txt) do
      [_, phone] -> phone
      nil -> "N/A"
    end
  end


  @doc """
  Extract the applicant's date of application from the LinkedIn email.
  """
  def get_date(txt) do
    {:ok, rx } = Regex.compile(~S"^Date:\s+(.+)\s+\(.+$", "um")
    Regex.run(rx, txt) |> List.last
  end


  @doc """
  Extract the name of the open position and the applicant's name from the
  LinkedIn email.
  """
  def get_name(txt) do
    txt = clean_utfs(txt)
    { :ok, rx } = Regex.compile(~S"You have received an application for (.+) from (.+)\s+View", "ums")
    [_, pos, name] = Regex.run(rx, txt)
    name = String.split(name) |> Enum.map &String.capitalize/1
    {pos, Enum.join(name, " ")}
  end


  @doc """
  Convert UTF-8 bytes back to unicode runes.
  """
  def clean_utfs(txt) do
    txt = Regex.replace(~R/=\r?\n/ms, txt, "", [:global])
    utfs = Regex.scan(~r/(=[0-9A-F]{2}){2,3}/, txt) |> Enum.map(&List.first/1)
    do_clean_utfs(utfs, txt)
  end


  @doc """
  Tail recursive function that does the actual work of converting UTF-8
  bytes back to unicode runes.
  """
  def do_clean_utfs([], txt), do: txt
  def do_clean_utfs([utf|tail], txt) do
    rune = String.split(utf, "=", trim: true)
      |> Enum.map(fn x -> String.to_integer(x, 16) end)
      |> :erlang.list_to_binary
    txt = String.replace(txt, utf, rune)
    do_clean_utfs(tail, txt)
  end


  @doc """
  Attempt to find the names of attachments buried in the email.
  Returns nil or a list of strings (the attachment file names).
  """
  def get_attachment(txt) do
    { :ok, rx } = Regex.compile(~S'attachment;\s+filename="?([^\r\n"]+)"?', "ums")
    case Regex.scan(rx, txt) do
      [[_|matches]] -> matches
      [] -> []
      matches ->
        matches = matches |> Enum.map(fn([_|match]) -> match end)
        List.flatten(matches)
    end
  end


  @doc """
  Extract the data from the applicants' emails, sort the CSV records
  and print them to stdout. Every email is scanned inside a dedicated
  erlang process.
  """
  def scan_files(path, show_pos \\ false) do
    me = self
    Path.wildcard(path <> "/*.eml")
    |>  Enum.map(fn(fpath) ->
          spawn_link fn ->
            send me, {self, scan_file(fpath, show_pos)}
          end
        end)
    |>  Enum.map(fn(_) ->
          receive do {_, result} -> result end
        end)
    |> Enum.sort
  end


  defp print_help() do
    help_text = """
      This tool scans a collection of application emails sent by
      LinkedIn and extracts the applicants' name, email, phone and
      date of application.

        --help      print this help
        --path P    look for *.eml file to scan in this drectory
        --seq       scan files sequentially in the same process
        --show-pos  show the position the person applied for as well
      """
    IO.puts help_text
  end
end
