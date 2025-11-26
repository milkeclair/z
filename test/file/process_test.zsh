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

z.t.describe "z.file.make_with_dir"; {
  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成する"; {
      z.dir.make path=/tmp/z_t
      z.file.make_with_dir path=/tmp/z_t/file_make_with_dir.txt

      z.file.exist /tmp/z_t/file_make_with_dir.txt

      z.t.expect.status.true
    }
  }

  z.t.context "親ディレクトリが存在しない場合"; {
    z.t.it "親ディレクトリごとファイルを作成する"; {
      z.file.make_with_dir path=/tmp/z_t/non_existent_dir/file_make_with_dir.txt

      z.file.exist /tmp/z_t/non_existent_dir/file_make_with_dir.txt
      z.dir.exist /tmp/z_t/non_existent_dir

      z.t.expect.status.true
    }
  }

  z.t.context "ファイルが存在する場合"; {
    z.t.it "何もしない"; {
      z.dir.make path=/tmp/z_t/existent_dir
      z.file.make path=/tmp/z_t/existent_dir/file_make_with_dir.txt

      z.file.make_with_dir path=/tmp/z_t/existent_dir/file_make_with_dir.txt

      z.file.exist /tmp/z_t/existent_dir/file_make_with_dir.txt
      z.dir.exist /tmp/z_t/existent_dir

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

z.t.describe "z.file.write.last"; {
  z.t.context "すでにファイルが存在する場合"; {
    z.t.it "内容を末尾に追加する"; {
      z.dir.make path=/tmp/z_t
      z.file.write path=/tmp/z_t/file_write_last.txt content="line1"
      z.file.write.last path=/tmp/z_t/file_write_last.txt content="line2"

      local content=$(cat /tmp/z_t/file_write_last.txt)

      z.t.expect.include $content "line1"
      z.t.expect.include $content "line2"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成して内容を書き込む"; {
      z.dir.make path=/tmp/z_t
      z.file.write.last path=/tmp/z_t/file_write_last_new.txt content="only line"

      local content=$(cat /tmp/z_t/file_write_last_new.txt)

      z.t.expect.include $content "only line"
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

z.t.describe "z.file.read.lines"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "行ごとの配列を返す"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_read_lines.txt
      echo -e "line1\nline2\nline3" > /tmp/z_t/file_read_lines.txt

      z.file.read.lines path=/tmp/z_t/file_read_lines.txt

      z.t.expect.reply.include "line1 line2 line3"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "REPLYを空にする"; {
      z.dir.make path=/tmp/z_t
      z.file.read.lines path=/tmp/z_t/non_existent_file_lines.txt

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.file.read.pick"; {
  z.t.context "ファイルが存在する場合"; {
    z.t.it "指定したwordが含まれる最初の行を返す"; {
      z.dir.make path=/tmp/z_t
      z.file.make path=/tmp/z_t/file_read_pick.txt
      echo -e "apple banana\norange grape\nbanana cherry" > /tmp/z_t/file_read_pick.txt

      z.file.read.pick path=/tmp/z_t/file_read_pick.txt word="banana"

      z.t.expect.reply.include "apple banana"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "REPLYを空にする"; {
      z.dir.make path=/tmp/z_t
      z.file.read.pick path=/tmp/z_t/non_existent_file_pick.txt word="banana"

      z.t.expect.reply.null
    }
  }
}
