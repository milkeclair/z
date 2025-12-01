source ${z_main}

z.t.describe "z.file.make"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.exists /tmp/z_t/file_make.txt

      z.t.expect.status.is.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/non_existent_dir/file_make.txt

      z.file.not.exists /tmp/z_t/non_existent_dir/file_make.txt
      z.dir.not.exists /tmp/z_t/non_existent_dir

      z.t.expect.status.is.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_make.txt
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.exists /tmp/z_t/file_make.txt

      z.t.expect.status.is.true
    }
  }

  z.t.context "with_dirオプションがtrueの場合"; {
    z.t.it "親ディレクトリも作成する"; {
      z.file.make path=/tmp/z_t/parent_dir/nested/file_make.txt with_dir=true

      z.file.exists /tmp/z_t/parent_dir/nested/file_make.txt
      z.dir.exists /tmp/z_t/parent_dir/nested

      z.t.expect.status.is.true
    }
  }

  z.t.context "with_dirオプションがfalseの場合"; {
    z.t.it "親ディレクトリを作成しない"; {
      z.file.make path=/tmp/z_t/another_parent_dir/nested/file_make.txt with_dir=false

      z.file.not.exists /tmp/z_t/another_parent_dir/nested/file_make.txt
      z.dir.not.exists /tmp/z_t/another_parent_dir/nested

      z.t.expect.status.is.true
    }
  }
}

z.t.describe "z.file.write"; {
  z.t.context "すでにファイルが存在する場合"; {
    z.t.it "内容を上書きする"; {
      z.file.write path=/tmp/z_t/file_write.txt content="initial content"
      z.file.write path=/tmp/z_t/file_write.txt content="new content"

      local content=$(cat /tmp/z_t/file_write.txt)

      z.t.expect.includes $content "new content"
      z.t.expect.excludes $content "initial content"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成して内容を書き込む"; {
      z.dir.make path=/tmp/z_t
      z.file.write path=/tmp/z_t/file_write_new.txt content="fresh content"

      local content=$(cat /tmp/z_t/file_write_new.txt)

      z.t.expect.includes $content "fresh content"
    }
  }
}

z.t.describe "z.file.read"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "内容を返す"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_read.txt
      echo -n "file content" > /tmp/z_t/file_read.txt

      z.file.read path=/tmp/z_t/file_read.txt

      z.t.expect.reply.includes "file content"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "REPLYを空にする"; {
      z.dir.make path=/tmp/z_t
      z.file.read path=/tmp/z_t/non_existent_file.txt

      z.t.expect.reply.is.null
    }
  }
}
