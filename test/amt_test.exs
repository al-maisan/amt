defmodule AmtTest do
  use ExUnit.Case
  doctest Amt


  test "applicants's name is extracted correctly 1" do
    ts = """
      Hi Joe,
      You have received an application for bitcoin guru from jaNE dOe
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.agdvcw-c&amp=
      """
    assert Amt.get_name(ts) == {"bitcoin guru", "Jane Doe"}
  end


  test "applicants's name is extracted correctly 2" do
    ts = """
      Hi Joe,
      You have received an application for chief troublemaker from chArlY dE gauLLe
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.agdvcw-c&amp=
      """
    assert Amt.get_name(ts) == {"chief troublemaker", "Charly De Gaulle"}
  end


  test "applicants's name is extracted correctly 3" do
    ts = """
      Hi Joe,
      You have received an application for pointy-haired guy from Gulliver J=C3=B6=
      llo
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.aageqh-1t&am=
      """
    assert Amt.get_name(ts) == {"pointy-haired guy", "Gulliver Jöllo"}
  end


  test "applicants's name is extracted correctly 4" do
    ts = """
      Hi Joe,
      You have received an application for marketroid from =C3=89so Pi=
      ta
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
      """
    assert Amt.get_name(ts) == {"marketroid", "Éso Pita"}
  end


  test "applicants's name is extracted correctly 5" do
    ts = """
      Hi Joe,
      You have received an application for day dreamer from Xavo Rappaso=
      le MBA, MSc, BA Open
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.a9v2r7-1f&am=
      """
    assert Amt.get_name(ts) == {"day dreamer", "Xavo Rappasole Mba, Msc, Ba Open"}
  end


  test "applicants's name is extracted correctly 6" do
    ts = """
      Hi Joe,
      You have received an application for keyboard trasher from Gagga Randp=
      ek
      View all applicants: https://www.example.com/e/v2?e=3D4vz24.a9v2r7-1f&am=
      """
    assert Amt.get_name(ts) == {"keyboard trasher", "Gagga Randpek"}
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


  test "test email address extraction" do
    ts1 = """
      Contact InformationEmail: abx.fgh@exact.ly
      """
    assert Amt.get_email(ts1) == "abx.fgh@exact.ly"
  end


  test "test phone number extraction with a number supplied" do
    ts1 = """
      Phone: +56964956548
      """
    assert Amt.get_phone(ts1) == "+56964956548"
  end


  test "test phone number extraction w/o a supplied number" do
    ts1 = """
      No phone number supplied :(
      """
    assert Amt.get_phone(ts1) == "N/A"
  end


  test "test date extraction" do
    ts1 = """
      To: xyz <xyz@example.com>
      Date: Mon, 4 May 2015 22:40:57 +0000 (UTC)
      X-LinkedIn-Class: EMAIL-DEFAULT
      """
    assert Amt.get_date(ts1) == "Mon, 4 May 2015 22:40:57 +0000"
  end
end


# -------------------------------------------------------------


defmodule AmtFilesTest do
  use ExUnit.Case


  setup context do
    {fpath, 0} = System.cmd("mktemp", ["exu.XXXXX.amt"])
    fpath = String.rstrip(fpath)
    write_file(fpath, context[:content])

    on_exit fn ->
      System.cmd("rm", ["-f", fpath])
    end

    {:ok, fpath: fpath}
  end


  @tag content: """
    To: xyz <xyz@example.com>
    Date: Mon, 4 May 2015 22:40:57 +0000 (UTC)
    X-LinkedIn-Class: EMAIL-DEFAULT
    Hi Joe,
    You have received an application for saure-Gurken-Einmacher from =C3=89so Pi=
    ta
    View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
    Contact InformationEmail: cde.fgh@exact.ly
    Phone: +56964956548
    """
  test "scan_file() works", context do
    expected = "Éso Pita;cde.fgh@exact.ly;+56964956548;Mon, 4 May 2015 22:40:57 +0000"
    actual = Amt.scan_file(context[:fpath])
    assert actual == expected
  end


  @tag content: """
    To: xbt <xbt@example.com>
    Date: Mon, 8 June 2017 12:54:32 +0000 (UTC)
    X-LinkedIn-Class: EMAIL-DEFAULT
    Hi Joe,
    You have received an application for millionaire from Gulliver J=C3=B6=
    llo
    View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
    Contact InformationEmail: cdg.wtg@ultimate.ly
    Phone: +469659560575
    """
  test "scan_file() prepends the name of the open position", context do
    expected = "millionaire;Gulliver Jöllo;cdg.wtg@ultimate.ly;+469659560575;Mon, 8 June 2017 12:54:32 +0000"
    actual = Amt.scan_file(context[:fpath], true)
    assert actual == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end


# -------------------------------------------------------------


defmodule AmtMultiFilesTest do
  use ExUnit.Case


  @test_files_content ["""
    To: xyz <xyz@example.com>
    Date: Mon, 4 May 2015 22:40:57 +0000 (UTC)
    X-LinkedIn-Class: EMAIL-DEFAULT
    Hi Joe,
    You have received an application for saure-Gurken-Einmacher from =C3=89so Pi=
    ta
    View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
    Contact InformationEmail: cde.fgh@exact.ly
    Phone: +56964956548
    """, """
    To: xbt <xbt@example.com>
    Date: Mon, 8 June 2017 12:54:32 +0000 (UTC)
    X-LinkedIn-Class: EMAIL-DEFAULT
    Hi Joe,
    You have received an application for millionaire from Gulliver J=C3=B6=
    llo
    View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
    Contact InformationEmail: cdg.wtg@ultimate.ly
    Phone: +469659560575
    """]


  setup context do
    {tpath, 0} = System.cmd("mktemp", ["-d"])
    tpath = String.rstrip(tpath)
    context[:test_data] |> Enum.map(fn x ->
      {fpath, 0} = System.cmd("mktemp", ["-p", tpath, "amt.XXXXX.eml"])
      fpath = String.rstrip(fpath)
      write_file(fpath, x)
    end)

    on_exit fn ->
      System.cmd("rm", ["-rf", tpath])
    end

    {:ok, tpath: tpath}
  end


  @tag test_data: @test_files_content
  test "scan_files() works", context do
    expected = [
      "millionaire;Gulliver Jöllo;cdg.wtg@ultimate.ly;+469659560575;Mon, 8 June 2017 12:54:32 +0000",
      "saure-Gurken-Einmacher;Éso Pita;cde.fgh@exact.ly;+56964956548;Mon, 4 May 2015 22:40:57 +0000"]
    actual = Amt.scan_files(context[:tpath], true)
    assert actual == expected
  end


  @tag test_data: @test_files_content
  test "scan_files_sequentially() works", context do
    expected = [
      "Gulliver Jöllo;cdg.wtg@ultimate.ly;+469659560575;Mon, 8 June 2017 12:54:32 +0000",
      "Éso Pita;cde.fgh@exact.ly;+56964956548;Mon, 4 May 2015 22:40:57 +0000"]
    actual = Amt.scan_files_sequentially(context[:tpath])
    assert actual == expected
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end
