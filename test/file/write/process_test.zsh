source ${z_main}

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
