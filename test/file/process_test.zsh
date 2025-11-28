source ${z_main}

z.t.describe "z.file.make"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.exist /tmp/z_t/file_make.txt

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/non_existent_dir/file_make.txt

      z.file.not_exist /tmp/z_t/non_existent_dir/file_make.txt
      z.dir.not_exist /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_make.txt
      z.file.make path=/tmp/z_t/file_make.txt

      z.file.exist /tmp/z_t/file_make.txt

      z.t.expect.status.true
    }
  }
}

z.t.describe "z.file.write"; {
  z.t.context "すでにファイルが存在する場合"; {
    z.t.it "内容を上書きする"; {
      z.file.write path=/tmp/z_t/file_write.txt content="initial content"
      z.file.write path=/tmp/z_t/file_write.txt content="new content"

      local content=$(cat /tmp/z_t/file_write.txt)

      z.t.expect.include $content "new content"
      z.t.expect.exclude $content "initial content"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成して内容を書き込む"; {
      z.dir.make path=/tmp/z_t
      z.file.write path=/tmp/z_t/file_write_new.txt content="fresh content"

      local content=$(cat /tmp/z_t/file_write_new.txt)

      z.t.expect.include $content "fresh content"
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

      z.t.expect.reply.include "file content"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "REPLYを空にする"; {
      z.dir.make path=/tmp/z_t
      z.file.read path=/tmp/z_t/non_existent_file.txt

      z.t.expect.reply.null
    }
  }
}
