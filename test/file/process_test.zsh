source ${z_main}

z.t.describe "z.file.make"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.is /tmp/z_t/file_make.txt

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "何もしない"; {
      z.file.make path=/tmp/z_t/non_existent_dir/file_make.txt

      z.file.is_not /tmp/z_t/non_existent_dir/file_make.txt
      z.dir.is_not /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.is /tmp/z_t/file_make.txt

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.file.make_with_dir"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.file.make_with_dir path=/tmp/z_t/file_make_with_dir.txt

      z.file.is /tmp/z_t/file_make_with_dir.txt

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "親ディレクトリごとファイルを作成する"; {
      z.file.make_with_dir path=/tmp/z_t/non_existent_dir/file_make_with_dir.txt

      z.file.is /tmp/z_t/non_existent_dir/file_make_with_dir.txt
      z.dir.is /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.file.make_with_dir path=/tmp/z_t/non_existent_dir/file_make_with_dir.txt

      z.file.is /tmp/z_t/non_existent_dir/file_make_with_dir.txt
      z.dir.is /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }
}
