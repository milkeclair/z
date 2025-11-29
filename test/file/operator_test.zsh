source ${z_main}

z.t.describe "z.file.exist"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "0を返す"; {
      z.file.make path=/tmp/z_t/file_has.txt with_dir=true

      z.file.exist /tmp/z_t/file_has.txt

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "1を返す"; {
      z.file.exist /tmp/z_t/file_has_not.txt

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.file.not_exist"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "0を返す"; {
      z.file.not_exist /tmp/z_t/file_has_not.txt

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "1を返す"; {
      z.file.make path=/tmp/z_t/file_has.txt with_dir=true

      z.file.not_exist /tmp/z_t/file_has.txt

      z.t.expect.status.false
    }
  }
}
