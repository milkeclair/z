source ${z_main}

z.t.describe "z.file.exists"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "0を返す"; {
      z.file.make path=/tmp/z_t/file_has.txt with_dir=true

      z.file.exists /tmp/z_t/file_has.txt

      z.t.expect.status.is.true
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "1を返す"; {
      z.file.exists /tmp/z_t/file_has_not.txt

      z.t.expect.status.is.false
    }
  }
}
