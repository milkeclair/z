source ${z_main}

z.t.describe "z.dir.exists"; {
  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "0を返す"; {
      z.dir.make path=/tmp/z_t/dir_is

      z.dir.exists /tmp/z_t/dir_is

      z.t.expect.status.is.true
    }
  }

  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "1を返す"; {
      z.dir.exists /tmp/not_exists_dir

      z.t.expect.status.is.false
    }
  }
}
