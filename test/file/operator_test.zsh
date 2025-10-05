source ${z_main}

z.t.describe "z.file.is"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "0を返す"; {
      z.file.make_with_dir /tmp/z_test/file_has.txt

      z.file.is /tmp/z_test/file_has.txt

      z.t.expect_status.true
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "1を返す"; {
      z.file.is /tmp/z_test/file_has_not.txt

      z.t.expect_status.false
    }
  }
}

z.t.describe "z.file.is_not"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "0を返す"; {
      z.file.is_not /tmp/z_test/file_has_not.txt

      z.t.expect_status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "1を返す"; {
      z.file.make_with_dir /tmp/z_test/file_has.txt

      z.file.is_not /tmp/z_test/file_has.txt

      z.t.expect_status.false
    }
  }
}
