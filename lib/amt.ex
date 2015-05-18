defmodule Amt do
  @moduledoc """
  Application management tool. Parses application emails sent by
  LinkedIn and creates a CSV formatted data sheet (delimited by ';').
  """

  def main(argv) do
    { parse, _, _ } = OptionParser.parse(
      argv, strict: [help: :boolean, seq: :boolean, show_pos: :boolean,
                     path: :string, attachments: :string])

    if parse[:path] != nil do
      if File.exists?(parse[:attachments]) do
        IO.puts "Attachments directory '#{parse[:attachments]}' already exists!"
        System.halt(101)
      else
        File.mkdir_p!(parse[:attachments])
      end
      if parse[:seq] do
        scan_files_sequentially(parse[:path], parse[:attachments], parse[:show_pos])
      else
        scan_files(parse[:path], parse[:attachments], parse[:show_pos])
      end |> Enum.each(fn(x) -> IO.puts(x) end)
    else
      print_help()
    end
  end


  defp print_help() do
    help_text = """
      This tool scans a collection of application emails sent by
      LinkedIn and extracts the applicants' name, email, phone and
      date of application.

        --attachments P  store attachments in directory P, the tool aborts
                         if P exists already (exit code 101)
        --help           print this help
        --path P         look for *.eml file to scan in directory P
        --seq            scan files sequentially in the same process
        --show-pos       show the position the person applied for as well
      """
    IO.puts help_text
  end


  @doc """
  Extract the data from the applicants' emails, sort the CSV records
  and print them to stdout. Emails are scanned sequentially by the same
  process.
  """
  def scan_files_sequentially(path, atmts_dir, show_pos \\ false) do
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
    {mudata, 0} = System.cmd("mu", ["extract", path])
    mudata = get_attachment_data(mudata)
    if show_pos do
      {Enum.join([pos, name, email, phone, date], ";"), {name, mudata}}
    else
      {Enum.join([name, email, phone, date], ";"), {name, mudata}}
    end
  end


  def get_attachment_data(mudata) do
    mudata
    |> String.split(~R/\n/)
    |> Enum.filter(fn x -> Regex.match?(~R/attach/, x) end)
    |> Enum.map(&String.split/1)
    |> Enum.map(fn x -> Enum.take(x, 2) end)
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
  def get_attachments(txt) do
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
  def scan_files(emails_dir, atmts_dir, show_pos \\ false) do
    me = self
    Path.wildcard(emails_dir <> "/*.eml")
    |>  Enum.map(fn(fpath) ->
          spawn_link fn ->
            send me, {fpath, scan_file(fpath, show_pos)}
          end
        end)
    |>  Enum.map(fn(_) ->
          receive do {fpath, {result, adata}} ->
            extract_attachments(fpath, atmts_dir, adata)
            result
          end
        end)
    |> Enum.sort
  end


  def extract_attachments(email_path, atmts_dir, {name, atmt_data}) do
    if length(atmt_data) > 0 do
      {temp_dir, 0} = System.cmd("mktemp", ["-d"])
      temp_dir = String.rstrip(temp_dir)
      atmt_indices = atmt_data |> Enum.map(fn [i, _] -> i end)
      atmt_indices = Enum.join(atmt_indices, ",")
      mu_args = ["extract", "-a", "--target-dir=#{temp_dir}", email_path]
      IO.inspect mu_args
      {_, 0} = System.cmd("mu", ["extract", "-a", "--target-dir=#{temp_dir}", email_path])
      move_attachments(temp_dir, atmts_dir, name)
      System.cmd("rm", ["-rf", temp_dir])
    end
  end

  def move_attachments(temp_dir, atmts_dir, name) do
    prefix = Regex.replace(~R/\s+/, name, "-", [:global])
    prefix = atmts_dir <> "/" <> prefix
    files = File.ls!(temp_dir) |> Enum.map(fn f -> temp_dir <> "/" <> f end)
    IO.inspect "files = #{files}"
    do_move_attachments(files, 0, prefix)
  end

  def do_move_attachments([], counter, _), do: counter
  def do_move_attachments([file|files], counter, prefix) do
    ext = Path.extname(file)
    target_path = if counter > 0 do
      prefix <> "-" <> to_string(counter) <> ext
    else
      prefix <> ext
    end
    {_, 0} = System.cmd("mv", [file, target_path])
    do_move_attachments(files, (counter + 1), prefix)
  end

end
