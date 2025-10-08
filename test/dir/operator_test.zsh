source ${z_main}

z.t.describe "z.dir.is"; {
  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "0を返す"; {
      z.dir.make /tmp/z_test/dir_is

      z.dir.is /tmp/z_test/dir_is

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "1を返す"; {
      z.dir.is /tmp/not_exists_dir

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.dir.is_not"; {
  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "0を返す"; {
      z.dir.is_not /tmp/not_exists_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "1を返す"; {
      z.dir.make /tmp/z_test/dir_is_not

      z.dir.is_not /tmp/z_test/dir_is_not

      z.t.expect.status.false
    }
  }
}
