defmodule Amt do
  @moduledoc """
  Application management tool. Parses application emails sent by
  LinkedIn and creates a CSV formatted data sheet (delimited by ';').
  """

  def aname(email) do
    {:ok, regex} = Regex.compile("^You have received an application for .+ from (.+)$")
    nl = Regex.run(regex,email) |> List.last |> String.split |> Enum.map &String.capitalize/1
    Enum.join(nl, " ")
  end

end
