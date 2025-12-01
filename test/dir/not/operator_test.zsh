source ${z_main}

z.t.describe "z.dir.not.exists"; {
  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "0を返す"; {
      z.dir.not.exists /tmp/not_exists_dir

      z.t.expect.status.is.true
    }
  }

  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "1を返す"; {
      z.dir.make path=/tmp/z_t/dir_is_not

      z.dir.not.exists /tmp/z_t/dir_is_not

      z.t.expect.status.is.false
    }
  }
}
