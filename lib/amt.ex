defmodule Amt do
  @moduledoc """
  Application management tool. Parses application emails sent by
  LinkedIn and creates a CSV formatted data sheet (delimited by ';').
  """

  def main(argv) do
    { parse, _, _ } = OptionParser.parse(argv, strict: [help: :boolean, path: :string])
    if parse[:help] == true do
      print_help()
    end
    if parse[:path] != nil do
       scan_files(parse[:path])
    else
      print_help()
    end
  end

  def print_help() do
    help_text = """
      This tool scans a collection of application emails sent by
      LinkedIn and extracts the applicants' name, email, phone and
      date of application.

        --help      prints this help
        --path P    looks for *.eml file to scan in this drectory
      """
    IO.puts help_text
  end

  def scan_files(path) do
    IO.puts do_scan_files(Path.wildcard(Enum.join([path, "*.eml"], "/")), [])
  end

  def do_scan_files([], result), do: result

  def do_scan_files([h|tail], result) do
    { :ok, body } = File.read(h)
    name = aname(body)
    email = aemail(body)
    phone = aphone(body)
    date = adate(body)
    record = Enum.join([name, email, phone, date], ";")
    do_scan_files(tail, [result|record])
  end

  @doc """
  Extract the applicant's email address from the LinkedIn email.
  """
  def aemail(txt) do
    { :ok, rx } = Regex.compile(~S"Contact InformationEmail:\s+(\S+)", "ums")
    Regex.run(rx, txt) |> List.last
  end

  @doc """
  Extract the applicant's phone number from the LinkedIn email.
  """
  def aphone(txt) do
    {:ok, rx } = Regex.compile(~S"Phone:\s*(\+?[\d\s]+\d)", "ums")
    Regex.run(rx, txt) |> List.last
  end

  @doc """
  Extract the applicant's date of application from the LinkedIn email.
  """
  def adate(txt) do
    {:ok, rx } = Regex.compile(~S"^Date:\s+(.+)\s+\(.+$", "um")
    Regex.run(rx, txt) |> List.last
  end

  @doc """
  Extract the applicant's name from the LinkedIn email.
  """
  def aname(txt) do
    txt = clean_utfs(txt)
    { :ok, rx } = Regex.compile(~S"You have received an application for .+ from (.+)\s+View", "ums")
    nl = Regex.run(rx, txt) |> List.last |> String.split |> Enum.map &String.capitalize/1
    Enum.join(nl, " ")
  end

  @doc """
  Convert UTF-8 bytes back to unicode runes.
  """
  def clean_utfs(txt) do
    txt = Regex.replace(~R/=\r?\n/ms, txt, "", [:global])
    utfs = Regex.scan(~r/(=[0-9A-F]{2}){2,3}/, txt) |> Enum.map(&List.first/1)
    do_clean_utfs(utfs, txt)
  end

  def do_clean_utfs([], txt), do: txt

  def do_clean_utfs([utf|remaining_utfs], txt) do
    rune = String.split(utf, "=", trim: true) |> Enum.map(fn x -> String.to_integer(x, 16) end) |> :erlang.list_to_binary
    txt = String.replace(txt, utf, rune)
    do_clean_utfs(remaining_utfs, txt)
  end

end
