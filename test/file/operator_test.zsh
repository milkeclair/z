source ${z_main}

z.t.describe "z.file.is"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "0を返す"; {
      z.file.make_with_dir path=/tmp/z_t/file_has.txt

      z.file.is /tmp/z_t/file_has.txt

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "1を返す"; {
      z.file.is /tmp/z_t/file_has_not.txt

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.file.is_not"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "0を返す"; {
      z.file.is_not /tmp/z_t/file_has_not.txt

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "1を返す"; {
      z.file.make_with_dir path=/tmp/z_t/file_has.txt

      z.file.is_not /tmp/z_t/file_has.txt

      z.t.expect.status.false
    }
  }
}
