defmodule Amt do
  @moduledoc """
  Application management tool. Parses application emails sent by
  LinkedIn and creates a CSV formatted data sheet (delimited by ';').
  """

  def aemail(txt) do
    { :ok, rx } = Regex.compile(~S"Contact InformationEmail:\s+(\S+)$")
    Regex.run(rx, txt) |> List.last
  end

  def aname(txt) do
    txt = clean_utfs(txt)
    { :ok, rx } = Regex.compile(~S"You have received an application for .+ from (.+)\s+View", "ums")
    nl = Regex.run(rx, txt) |> List.last |> String.split |> Enum.map &String.capitalize/1
    Enum.join(nl, " ")
  end

  def clean_utfs(txt) do
    txt = Regex.replace(~R/=\n/, txt, "", [:global])
    utfs = Regex.scan(~r/(=[0-9a-fA-F]{2})+/, txt) |> Enum.map(&List.first/1)
    do_clean_utfs(utfs, txt)
  end

  def do_clean_utfs([], txt), do: txt

  def do_clean_utfs([utf|remaining_utfs], txt) do
    rune = String.split(utf, "=", trim: true) |> Enum.map(fn x -> String.to_integer(x, 16) end) |> :erlang.list_to_binary
    txt = String.replace(txt, utf, rune)
    do_clean_utfs(remaining_utfs, txt)
  end

end
