source ${z_main}

z.t.describe "z.dir.make"; {
  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "ディレクトリを作成する"; {
      z.dir.make path=/tmp/z_t/dir_make

      z.dir.exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "親ディレクトリごと作成する"; {
      z.dir.make path=/tmp/z_t/dir_make/sub_dir

      z.dir.exist /tmp/z_t/dir_make/sub_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t/dir_make

      z.dir.exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.dir.remove"; {
  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "ディレクトリを削除する"; {
      z.dir.make path=/tmp/z_t/dir_make
      z.dir.remove path=/tmp/z_t/dir_make

      z.dir.not_exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在し、中にファイルがある場合"; {
    z.t.it "ファイルごとディレクトリを削除する"; {
      z.dir.make path=/tmp/z_t/dir_make
      z.file.make path=/tmp/z_t/dir_make/file.txt
      z.dir.remove path=/tmp/z_t/dir_make

      z.dir.not_exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在し、サブディレクトリがある場合"; {
    z.t.it "サブディレクトリごとディレクトリを削除する"; {
      z.dir.make path=/tmp/z_t/dir_make/sub_dir
      z.file.make path=/tmp/z_t/dir_make/sub_dir/file.txt
      z.dir.remove path=/tmp/z_t/dir_make

      z.dir.not_exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }

  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t/dir_make
      z.dir.remove path=/tmp/z_t/dir_make

      z.dir.not_exist /tmp/z_t/dir_make

      z.t.expect.status.true
    }
  }
}
