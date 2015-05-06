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

  test "applicants's name is extracted correctly 4" do
    ts = """
      Hi Joe,
      You have received an application for IT security expert from =C3=89so Pi=
      ta
      View all applicants: https://www.linkedin.com/e/v2?e=3D4vz24-i9b044qe-3o&am
      """
    assert Amt.aname(ts) == "Éso Pita"
  end

  test "clean_utfs deals with the utf-8 bytes correctly" do
    ts1 = """
      Gulliver J=C3=B6=
      llo
      View
      """
    ts2 = """
      Gulliver J=C3=B6=
      llo=C3=BB
      View
      """
    assert Amt.clean_utfs(ts1) == "Gulliver Jöllo\nView\n"
    assert Amt.clean_utfs(ts2) == "Gulliver Jölloû\nView\n"
  end

  test "utf-8 bytes handling with 0+ occurrences" do
    assert Amt.do_clean_utfs([], "expected") == "expected"
    assert Amt.do_clean_utfs(["=c3=b6"], "J=c3=b6llo") == "Jöllo"
    assert Amt.do_clean_utfs(["=c3=b6", "=c3=bb"], "J=c3=b6llo=c3=bb") == "Jölloû"
  end

  test "test email extraction" do
    ts1 = """
      Contact InformationEmail: abx.fgh@exact.ly
      """
    assert Amt.aemail(ts1) == "abx.fgh@exact.ly"
  end

end
