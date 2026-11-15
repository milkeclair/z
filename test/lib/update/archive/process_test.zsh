source "$z_main"

z.t.describe "z.update.archive._download"; {
  z.t.context "明示したbranchを取得する場合"; {
    z.t.it "URLと出力先を渡しarchive pathを返す"; {
      local dir=/tmp/z_t/update_download/success
      z.dir.remove path=/tmp/z_t/update_download
      z.dir.make path="$dir"

      z.t.mock name=curl behavior="z.file.write path=\"$dir/source.tar.gz\" content=archive"

      z.update.archive._download dir="$dir" branch=topic/change
      local download_status=$?
      local archive=$REPLY

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$download_status" 0
      z.t.expect "$archive" "$dir/source.tar.gz"
      z.t.expect "$call" "-fLsS https://github.com/milkeclair/z/archive/refs/heads/topic/change.tar.gz -o $dir/source.tar.gz"

      z.dir.remove path=/tmp/z_t/update_download
    }
  }

  z.t.context "branchがない場合"; {
    z.t.it "mainを取得する"; {
      local dir=/tmp/z_t/update_download/default
      z.dir.make path="$dir"

      z.t.mock name=curl behavior="z.file.write path=\"$dir/source.tar.gz\" content=archive"

      z.update.archive._download dir="$dir"

      z.t.mock.result name=curl
      z.t.expect.includes "$REPLY" "/refs/heads/main.tar.gz"

      z.dir.remove path=/tmp/z_t/update_download
    }
  }

  z.t.context "curlが失敗した場合"; {
    z.t.it "失敗してREPLYを空にする"; {
      local dir=/tmp/z_t/update_download/failure
      z.dir.make path="$dir"

      z.t.mock name=curl behavior="z.file.write path=\"$dir/source.tar.gz\" content=partial; return 22"

      z.update.archive._download dir="$dir"
      local download_status=$?
      local result=$REPLY

      z.t.expect "$download_status" 1
      REPLY=$result
      z.t.expect.reply.is.null

      z.file.not.exists "$dir/source.tar.gz"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_download
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "curlを実行しない"; {
      z.t.mock name=curl

      z.update.archive._download
      local download_status=$?

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$download_status" 1
      REPLY=$call
      z.t.expect.reply.is.null
    }
  }

  z.t.context "dirが存在しない場合"; {
    z.t.it "curlを実行しない"; {
      z.t.mock name=curl

      z.update.archive._download dir=/tmp/z_t/update_download_absent
      local download_status=$?

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$download_status" 1
      REPLY=$call
      z.t.expect.reply.is.null
    }
  }

  z.t.context "branchが空の場合"; {
    z.t.it "z.arg.namedのdefaultに従ってmainを使う"; {
      local dir=/tmp/z_t/update_download/empty_branch
      z.dir.make path="$dir"

      z.t.mock name=curl behavior="z.file.write path=\"$dir/source.tar.gz\" content=archive"

      z.update.archive._download dir="$dir" branch=
      local download_status=$?

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$download_status" 0
      z.t.expect.includes "$call" "/refs/heads/main.tar.gz"

      z.dir.remove path=/tmp/z_t/update_download
    }
  }

  z.t.context "archive fileがすでにある場合"; {
    z.t.it "上書きしない"; {
      local dir=/tmp/z_t/update_download/existing
      z.dir.make path="$dir"
      z.file.write path="$dir/source.tar.gz" content=original

      z.t.mock name=curl

      z.update.archive._download dir="$dir"
      local download_status=$?

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$download_status" 1
      REPLY=$call
      z.t.expect.reply.is.null

      z.file.read path="$dir/source.tar.gz"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_download
    }
  }

}

z.t.describe "z.update.archive._extract"; {
  z.t.context "single source directoryのarchiveの場合"; {
    z.t.it "展開先source pathと内容を返す"; {
      local dir="/tmp/z_t/update_extract/with space"
      z.dir.remove path=/tmp/z_t/update_extract
      z.dir.make path="$dir/input/z-branch/lib"
      z.file.write path="$dir/input/z-branch/lib/value" content=source
      tar -czf "$dir/source.tar.gz" -C "$dir/input" z-branch

      z.update.archive._extract file="$dir/source.tar.gz" dir="$dir/output"
      local extract_status=$?
      local source_dir=$REPLY

      z.t.expect "$extract_status" 0
      z.t.expect "$source_dir" "$dir/output/z-branch"

      z.file.read path="$source_dir/lib/value"
      z.t.expect.reply source

      z.dir.remove path=/tmp/z_t/update_extract
    }
  }

  z.t.context "file引数がない場合"; {
    z.t.it "展開先を作らない"; {
      z.update.archive._extract dir=/tmp/z_t/update_extract_absent
      local extract_status=$?
      local result=$REPLY

      z.t.expect "$extract_status" 1
      REPLY=$result
      z.t.expect.reply.is.null

      z.dir.not.exists /tmp/z_t/update_extract_absent
      z.t.expect.status.is.true
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.archive._extract file=/tmp/not-an-archive

      z.t.expect.status.is.false
    }
  }

  z.t.context "archiveが壊れている場合"; {
    z.t.it "作成した展開先を除去する"; {
      local dir=/tmp/z_t/update_extract/invalid
      z.dir.make path="$dir"
      z.file.write path="$dir/source.tar.gz" content=invalid

      z.update.archive._extract file="$dir/source.tar.gz" dir="$dir/output" 2>/dev/null
      local extract_status=$?
      local result=$REPLY

      z.t.expect "$extract_status" 1
      REPLY=$result
      z.t.expect.reply.is.null

      z.dir.not.exists "$dir/output"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_extract
    }
  }

  z.t.context "top level directoryがない場合"; {
    z.t.it "失敗して展開先を除去する"; {
      local dir=/tmp/z_t/update_extract/flat
      z.dir.make path="$dir/input"
      z.file.write path="$dir/input/value" content=flat
      tar -czf "$dir/source.tar.gz" -C "$dir/input" value

      z.update.archive._extract file="$dir/source.tar.gz" dir="$dir/output"
      local extract_status=$?

      z.t.expect "$extract_status" 1

      z.dir.not.exists "$dir/output"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_extract
    }
  }

  z.t.context "top level directoryが複数ある場合"; {
    z.t.it "sourceを選ばず失敗する"; {
      local dir=/tmp/z_t/update_extract/multiple
      z.dir.make path="$dir/input/one"
      z.dir.make path="$dir/input/two"
      tar -czf "$dir/source.tar.gz" -C "$dir/input" one two

      z.update.archive._extract file="$dir/source.tar.gz" dir="$dir/output"
      local extract_status=$?

      z.t.expect "$extract_status" 1

      z.dir.not.exists "$dir/output"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_extract
    }
  }

  z.t.context "展開先がすでにある場合"; {
    z.t.it "既存fileを残す"; {
      local dir=/tmp/z_t/update_extract/existing
      z.dir.make path="$dir/output"
      z.file.write path="$dir/source.tar.gz" content=unused
      z.file.write path="$dir/output/value" content=original

      z.update.archive._extract file="$dir/source.tar.gz" dir="$dir/output"
      local extract_status=$?

      z.t.expect "$extract_status" 1

      z.file.read path="$dir/output/value"
      z.t.expect.reply original

      z.dir.remove path=/tmp/z_t/update_extract
    }
  }

}

