defmodule AmtTest do
  use ExUnit.Case
  doctest Amt

  test "applicants's name is extracted correctly 1" do
    ts = """
      Hi Joe,
      You have received an application for IT security expert from jaNE dOe
      View all applicants: https://www.linkedin.com/e/v2?e=3D4vz24-i9agdvcw-c&amp=
      """
    assert Amt.aname(ts) == "Jane Doe"
  end

  test "applicants's name is extracted correctly 2" do
    ts = """
      Hi Joe,
      You have received an application for IT security expert from chArlY dE gauLLe
      View all applicants: https://www.linkedin.com/e/v2?e=3D4vz24-i9agdvcw-c&amp=
      """
    assert Amt.aname(ts) == "Charly De Gaulle"
  end

  test "applicants's name is extracted correctly 3" do
    ts = """
      Hi Joe,
      You have received an application for IT security expert from Oliver N=C3=B6=
      then
      View all applicants: https://www.linkedin.com/e/v2?e=3D4vz24-i9aageqh-1t&am=
      """
    assert Amt.aname(ts) == "Oliver Nöthen"
  end

end
