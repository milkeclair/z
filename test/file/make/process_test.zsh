source ${z_main}

z.t.describe "z.file.make.with_dir"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.dir.make path=/tmp/z_t
      z.file.make.with_dir path=/tmp/z_t/file_make.with_dir.txt

      z.file.exist /tmp/z_t/file_make.with_dir.txt

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "親ディレクトリごとファイルを作成する"; {
      z.file.make.with_dir path=/tmp/z_t/non_existent_dir/file_make.with_dir.txt

      z.file.exist /tmp/z_t/non_existent_dir/file_make.with_dir.txt
      z.dir.exist /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t/existent_dir
      z.file.make path=/tmp/z_t/existent_dir/file_make.with_dir.txt

      z.file.make.with_dir path=/tmp/z_t/existent_dir/file_make.with_dir.txt

      z.file.exist /tmp/z_t/existent_dir/file_make.with_dir.txt
      z.dir.exist /tmp/z_t/existent_dir

      z.t.expect.status.true
    }
  }
}
