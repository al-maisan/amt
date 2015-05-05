defmodule AmtTest do
  use ExUnit.Case
  doctest Amt

  test "applicants's name is extracted correctly 1" do
    assert Amt.aname("You have received an application for IT security expert from amine RaCHed") == "Amine Rached"
  end

  test "applicants's name is extracted correctly 2" do
    assert Amt.aname("You have received an application for Mobile / Android developer from MuHAMmad UMER") == "Muhammad Umer"
  end
end
