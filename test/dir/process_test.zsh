source ${z_main}

z.t.describe "z.dir.make"; {
  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "ディレクトリを作成する"; {
      z.dir.make /tmp/z_test/dir_make

      z.dir.is /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "親ディレクトリごと作成する"; {
      z.dir.make /tmp/z_test/dir_make/sub_dir

      z.dir.is /tmp/z_test/dir_make/sub_dir

      z.t.expect_status.true
    }
  }

  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make /tmp/z_test/dir_make

      z.dir.is /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }
}

z.t.describe "z.dir.remove"; {
  z.t.context "ディレクトリが存在する場合"; {
    z.t.it "ディレクトリを削除する"; {
      z.dir.make /tmp/z_test/dir_make
      z.dir.remove /tmp/z_test/dir_make

      z.dir.is_not /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }

  z.t.context "ディレクトリが存在し、中にファイルがある場合"; {
    z.t.it "ファイルごとディレクトリを削除する"; {
      z.dir.make /tmp/z_test/dir_make
      z.file.make /tmp/z_test/dir_make/file.txt
      z.dir.remove /tmp/z_test/dir_make

      z.dir.is_not /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }

  z.t.context "ディレクトリが存在し、サブディレクトリがある場合"; {
    z.t.it "サブディレクトリごとディレクトリを削除する"; {
      z.dir.make /tmp/z_test/dir_make/sub_dir
      z.file.make /tmp/z_test/dir_make/sub_dir/file.txt
      z.dir.remove /tmp/z_test/dir_make

      z.dir.is_not /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }

  z.t.context "ディレクトリが存在しない場合"; {
    z.t.it "何もしない"; {
      z.dir.make /tmp/z_test/dir_make
      z.dir.remove /tmp/z_test/dir_make

      z.dir.is_not /tmp/z_test/dir_make

      z.t.expect_status.true
    }
  }
}
