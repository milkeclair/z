source ${z_main}

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
