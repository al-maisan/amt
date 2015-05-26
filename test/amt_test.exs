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
    assert Amt.get_name(ts) == {"day dreamer", "Xavo Rappasole Mba"}
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
    assert Amt.get_date(ts1) == "2015-May-04"
  end


  test "attachment data 1" do
    ts1 = """
      MIME-parts in this message:
        2 <none> text/plain [<none>] (2.3 kB)
        3 <none> text/html [<none>] (58.3 kB)
        4 resume_11.docx application/vnd.openxmlformats-officedocument.wordprocessingml.document [attach] (97.7 kB)
      """
    assert Amt.get_attachment_data(ts1) == [["4", "resume_11.docx"]]
  end


  test "attachment data 2" do
    ts1 = """
      MIME-parts in this message:
        1 <none> text/plain [<none>] (0.3 kB)
        2 a1.txt text/plain [attach] (0.0 kB)
        3 a2-blanks.txt text/plain [attach] (0.0 kB)
        4 a3.csv text/csv [attach] (0.0 kB)
      """
    assert Amt.get_attachment_data(ts1) == [["2", "a1.txt"], ["3", "a2-blanks.txt"], ["4", "a3.csv"]]
  end


  test "test attachment name scanning 1" do
    ts1 = """
      Content-Disposition: attachment; filename="ahdh.foe.CVEN 2.pdf"
      """
    assert Amt.get_attachments(ts1) == ["ahdh.foe.CVEN 2.pdf"]
  end


  test "test attachment name scanning 2" do
    ts1 = """
      Content-Disposition: attachment; 
          filename=Consultant_IT.SECURITY_CISSP_ENG_v2.pdf
      """
    assert Amt.get_attachments(ts1) == ["Consultant_IT.SECURITY_CISSP_ENG_v2.pdf"]
  end


  test "test attachment name scanning 3" do
    ts1 = """
      """
    assert Amt.get_attachments(ts1) == []
  end


  test "test attachment name scanning 4" do
    ts1 = """
      --------------040006040109000903050706
      Content-Type: text/plain; charset=UTF-8;
       name="a1.txt"
      Content-Transfer-Encoding: base64
      Content-Disposition: attachment;
       filename="a1.txt"

      YTFiMgo=
      --------------040006040109000903050706
      Content-Type: text/plain; charset=UTF-8;
       name="a2 blanks.txt"
      Content-Transfer-Encoding: base64
      Content-Disposition: attachment;
       filename="a2 blanks.txt"

      YzNkNAo=
      --------------040006040109000903050706
      Content-Type: text/csv;
       name="a3.csv"
      Content-Transfer-Encoding: quoted-printable
      Content-Disposition: attachment;
       filename="a3.csv"

      e5;f6

      --------------040006040109000903050706--

      --nt3ssTlh6hRvNxeHVMQHqWXk384t73XSd
      Content-Type: application/pgp-signature; name="signature.asc"
      Content-Description: OpenPGP digital signature
      Content-Disposition: attachment; filename="signature.asc"

      -----BEGIN PGP SIGNATURE-----
      Version: GnuPG v1

      iQIcBAEBCAAGBQJVWXEAAAoJEGGHXhlmLdW2LAYP/2Nj3dkg1LpIITPfLQT3XzI3
      dVwQGWeDAKoeSMZ+CrL27qiGKgDooEBrIVTWi6Q8Hp/YarmkAErBHEz6dtmaq6/U
      HD7+uMjV2YLyaHG24TqFP3vxFcWJqB9tDDL4P/jlnTgJ1NYqdZomEvtLtrwDq54P
      M70GLXf6nAuU5fyFO37Zau98/9xbN1qKGi84EhoQVHUB64U+NrjH96SSYKAF12AM
      T5/Lbr94UnTpss1E1ril3KRJwAAfI0oZk6vrxADh/t4XxXNApeBCgLYue9BKDv6V
      fDKdhxgmOTAjR96l+Ebs4P1IttpGESLyKdau+l7x1qzxq6bFhpczv4LTfytlLBa2
      vC4HHm9MKIbQBNTbTURLSn5stKd18EDHskouzaPTP4yopSl8m4Ai91ahC5jh4QbZ
      DYtS/dyNmQpOsewagVwfq1Ce8h4fLTApEP20ahVqt2JU/6qRaQLuissD7wV4bGDU
      /NigmzV15jBiUEoHhBd/i77kzUZJcPrxgwRHwTUwXs8E6Rq69PpMPviM2/v/ON3P
      L9H+zLrgm5Phf1bCROzu64y+ge7VwFJK5HoddsiTjUOCIijR5Qs+UTuAyFIw3Npq
      zcywNqaoniNfMjKj4ENxV+3XSY7DmSHoEY9uThfLsqubFb04o1WTzbgPDOzlHZyI
      rxlWtuE7OPTHAyPqqDcS
      =4jiJ
      -----END PGP SIGNATURE-----

      --nt3ssTlh6hRvNxeHVMQHqWXk384t73XSd--
      """
    assert Amt.get_attachments(ts1) == ["a1.txt", "a2 blanks.txt", "a3.csv", "signature.asc"]
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
    expected = {"Éso Pita;cde.fgh@exact.ly;'+56964956548;'2015-May-04", {"Éso Pita", []}}
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
    expected = {"millionaire;Gulliver Jöllo;cdg.wtg@ultimate.ly;'+469659560575;'2017-June-08", {"Gulliver Jöllo", []}}
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
    Date: Mon, 4 May 2015 22:40:57 +0000 (UTC)
    From: Glfheo Kefhf <fheh@fphfdd.cc>
    MIME-Version: 1.0
    To: Hofho Od <hdo@ddhp.cc>
    Subject: attachments
    Content-Type: multipart/mixed;
     boundary="------------040206090805020401010202"

    This is a multi-part message in MIME format.
    --------------040206090805020401010202
    Content-Type: text/plain; charset=utf-8
    Content-Transfer-Encoding: 8bit

    Hi Joe,
    You have received an application for saure-Gurken-Einmacher from =C3=89so Pi=
    ta
    View all applicants: https://www.example.com/e/v2?e=3D4vz24.b044qe-3o&am
    Contact InformationEmail: cde.fgh@exact.ly
    Phone: +56964956548

    --------------040206090805020401010202
    Content-Type: text/plain; charset=UTF-8;
     name="a1.txt"
    Content-Transfer-Encoding: base64
    Content-Disposition: attachment;
     filename="a1.txt"

    YTFiMgo=
    --------------040206090805020401010202
    Content-Type: text/plain; charset=UTF-8;
     name="a2 blanks.txt"
    Content-Transfer-Encoding: base64
    Content-Disposition: attachment;
     filename="a2 blanks.txt"

    YzNkNAo=
    --------------040206090805020401010202
    Content-Type: text/csv;
     name="a3.csv"
    Content-Transfer-Encoding: 7bit
    Content-Disposition: attachment;
     filename="a3.csv"

    e5;f6

    --------------040206090805020401010202--
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
    {atmts_dir, 0} = System.cmd("mktemp", ["-d"])
    atmts_dir = String.rstrip(atmts_dir)
    context[:test_data] |> Enum.map(fn x ->
      {fpath, 0} = System.cmd("mktemp", ["-p", tpath, "amt.XXXXX.eml"])
      fpath = String.rstrip(fpath)
      write_file(fpath, x)
    end)

    on_exit fn ->
      System.cmd("rm", ["-rf", tpath])
      System.cmd("rm", ["-rf", atmts_dir])
    end

    {:ok, tpath: tpath, atmts_dir: atmts_dir}
  end


  @tag test_data: @test_files_content
  test "scan_files() works", context do
    expected = [
      "millionaire;Gulliver Jöllo;cdg.wtg@ultimate.ly;'+469659560575;'2017-June-08",
      "saure-Gurken-Einmacher;Éso Pita;cde.fgh@exact.ly;'+56964956548;'2015-May-04"]
    actual = Amt.scan_files(context[:tpath], context[:atmts_dir], true)
    assert actual == expected

    expected_attachments = """
      4.0K Éso-Pita-1.txt
      4.0K Éso-Pita-2.csv
      4.0K Éso-Pita.txt
      total 12K
      """
    cmd = "ls -sh " <> context[:atmts_dir] <> " | sort"
    actual = :os.cmd(to_char_list(cmd))
    assert to_string(actual) == expected_attachments
  end


  @tag test_data: @test_files_content
  test "scan_files_sequentially() works", context do
    expected = [
      "Gulliver Jöllo;cdg.wtg@ultimate.ly;'+469659560575;'2017-June-08",
      "Éso Pita;cde.fgh@exact.ly;'+56964956548;'2015-May-04"]
    actual = Amt.scan_files_sequentially(context[:tpath], context[:atmts_dir])
    assert actual == expected

    expected_attachments = """
      4.0K Éso-Pita-1.txt
      4.0K Éso-Pita-2.csv
      4.0K Éso-Pita.txt
      total 12K
      """
    cmd = "ls -sh " <> context[:atmts_dir] <> " | sort"
    actual = :os.cmd(to_char_list(cmd))
    assert to_string(actual) == expected_attachments
  end


  defp write_file(path, content) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end
end
