source ${z_main}

z.t.describe "z.dir.exist"; {
  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "0を返す"; {
      z.dir.make path=/tmp/z_t/dir_is

      z.dir.exist /tmp/z_t/dir_is

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "1を返す"; {
      z.dir.exist /tmp/not_exists_dir

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.dir.not_exist"; {
  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "0を返す"; {
      z.dir.not_exist /tmp/not_exists_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "1を返す"; {
      z.dir.make path=/tmp/z_t/dir_is_not

      z.dir.not_exist /tmp/z_t/dir_is_not

      z.t.expect.status.false
    }
  }
}
