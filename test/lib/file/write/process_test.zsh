source ${z_main}

z.t.describe "z.file.write.last"; {
  z.t.context "すでにファイルが存在する場合"; {
    z.t.it "内容を末尾に追加する"; {
      z.dir.make path=/tmp/z_t
      z.file.write path=/tmp/z_t/file_write_last.txt content="line1"
      z.file.write.last path=/tmp/z_t/file_write_last.txt content="line2"

      local content=$(cat /tmp/z_t/file_write_last.txt)

      z.t.expect.includes $content "line1"
      z.t.expect.includes $content "line2"
    }
  }

  z.t.context "ファイルが存在しない場合"; {
    z.t.it "ファイルを作成して内容を書き込む"; {
      z.dir.make path=/tmp/z_t
      z.file.write.last path=/tmp/z_t/file_write_last_new.txt content="only line"

      local content=$(cat /tmp/z_t/file_write_last_new.txt)

      z.t.expect.includes $content "only line"
    }
  }
}

z.t.describe "z.file.write.literal"; {
  z.t.context "書き込み先がある場合"; {
    z.t.it "改行とバックスラッシュをそのまま保存する"; {
      z.dir.make path=/tmp/z_t/literal

      z.file.write.literal path=/tmp/z_t/literal/value content=$'line\\n\ntrue'

      z.t.expect.status.is.true
      z.file.read path=/tmp/z_t/literal/value
      z.t.expect.reply $'line\\n\ntrue'
    }

    z.t.it "null文字列と空文字を書き込める"; {
      z.dir.make path=/tmp/z_t/literal_empty

      z.file.write.literal path=/tmp/z_t/literal_empty/value content=null

      z.file.read path=/tmp/z_t/literal_empty/value
      z.t.expect.reply null

      z.file.write.literal path=/tmp/z_t/literal_empty/value content=

      z.t.expect.status.is.true
      z.file.read path=/tmp/z_t/literal_empty/value
      z.t.expect.reply.is.null
    }
  }

  z.t.context "上書きが禁止されている場合"; {
    z.t.it "既存ファイルを保持して失敗する"; {
      z.dir.make path=/tmp/z_t/literal_existing
      z.file.write path=/tmp/z_t/literal_existing/value content=before

      z.file.write.literal path=/tmp/z_t/literal_existing/value content=after overwrite=false 2>/dev/null

      z.t.expect.status.is.false
      z.file.read path=/tmp/z_t/literal_existing/value
      z.t.expect.reply before
    }
  }

  z.t.context "書き込みに失敗する場合"; {
    z.t.it "存在しない親directoryを成功として扱わない"; {
      z.file.write.literal path=/tmp/z_t/literal_missing/dir/value content=value 2>/dev/null

      z.t.expect.status.is.false
    }
  }
}
