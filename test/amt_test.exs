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
      You have received an application for IT security expert from Gulliver J=C3=B6=
      llo
      View all applicants: https://www.linkedin.com/e/v2?e=3D4vz24-i9aageqh-1t&am=
      """
    assert Amt.aname(ts) == "Gulliver Jöllo"
  end

  test "clean_utfs deals with the utf-8 bytes correctly" do
    ts = """
      Gulliver J=C3=B6=
      llo
      View
      """
    assert Amt.clean_utfs(ts) == "Gulliver Jöllo\nView\n"
  end

  test "utf-8 bytes handling with 0+ occurrences" do
    assert Amt.do_clean_utfs([], "expected") == "expected"
    assert Amt.do_clean_utfs(["=c3=b6"], "J=c3=b6llo") == "Jöllo"
    assert Amt.do_clean_utfs(["=c3=b6", "=c3=bb"], "J=c3=b6llo=c3=bb") == "Jölloû"
  end
end
