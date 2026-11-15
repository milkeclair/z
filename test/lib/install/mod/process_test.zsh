source "$z_main"

z.t.describe "z.install.mod.list"; {
  z.t.context "複数の導入状態が混在する場合"; {
    z.t.it "名前順に重複なく表示して各状態を緑・オレンジ・赤にする"; {
      local fixture=$(mktemp -d "/tmp/z mod list.XXXXXX")
      local z_root="$fixture/installed"
      local Z_INSTALL_BRANCH=topic/change
      local work_dir="$fixture/work"
      local fetch_calls=0
      z.dir.make path="$fixture/source/alpha"
      z.dir.make path="$fixture/source/beta"
      z.dir.make path="$fixture/source/gamma"
      z.dir.make path="$z_root/mod/alpha"
      z.dir.make path="$z_root/mod/beta"
      z.dir.make path="$z_root/mod/local-only"
      z.file.write path="$fixture/source/alpha/value" content=new
      z.file.write path="$z_root/mod/alpha/value" content=old
      z.file.write path="$fixture/source/beta/value" content=same
      z.file.write path="$z_root/mod/beta/value" content=same
      z.file.write path="$fixture/source/gamma/mod.zsh" content="touch \"$fixture/executed\""

      z.t.mock name=mktemp behavior="z.dir.make path=\"$work_dir\"; z.io \"$work_dir\""
      z.t.mock name="z.install.mod._fetch" behavior="((fetch_calls++)); z.return \"$fixture/source\""

      z.install.mod.list > "$fixture/output"
      local result_code=$?
      local result_reply=$REPLY
      local output=$(< "$fixture/output")

      z.t.mock.result name="z.install.mod._fetch"
      local fetch_args=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$result_reply" ""
      z.t.expect "$fetch_calls" 1
      z.t.expect "$fetch_args" "dir=$work_dir branch=topic/change"
      z.t.expect "$output" $'\033[38;5;208malpha [update-available]\033[0m\n\033[32mbeta [installed]\033[0m\n\033[31mgamma [not-installed]\033[0m\n\033[32mlocal-only [installed]\033[0m'

      z.dir.not.exists "$work_dir"
      z.t.expect.status.is.true

      z.file.not.exists "$fixture/executed"
      z.t.expect.status.is.true

      z.file.read path="$z_root/mod/alpha/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "導入済みmodがない場合"; {
    z.t.it "公開modを赤色で表示する"; {
      local fixture=$(mktemp -d /tmp/z_mod_list.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$fixture/source/example"
      z.t.mock name="z.install.mod._fetch" behavior="z.return \"$fixture/source\""

      z.install.mod.list > "$fixture/output"
      local result_code=$?
      local output=$(< "$fixture/output")

      z.t.expect "$result_code" 0
      z.t.expect "$output" $'\033[31mexample [not-installed]\033[0m'

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "公開modも導入済みmodもない場合"; {
    z.t.it "出力せず成功する"; {
      local fixture=$(mktemp -d /tmp/z_mod_list.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$fixture/source"
      z.t.mock name="z.install.mod._fetch" behavior="z.return \"$fixture/source\""

      z.install.mod.list > "$fixture/output"
      local result_code=$?

      z.t.expect "$result_code" 0
      [[ ! -s "$fixture/output" ]]
      z.t.expect.status.is.true

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "取得に失敗した場合"; {
    z.t.it "誤った一覧を出さず作業directoryを片付ける"; {
      local fixture=$(mktemp -d /tmp/z_mod_list.XXXXXX)
      local z_root="$fixture/installed"
      local work_dir="$fixture/work"
      z.t.mock name=mktemp behavior="z.dir.make path=\"$work_dir\"; z.io \"$work_dir\""
      z.t.mock name="z.install.mod._fetch" behavior="z.file.write path=\"$work_dir/partial\" content=partial; return 1"

      z.install.mod.list > "$fixture/output" 2>/dev/null
      local result_code=$?

      z.t.expect "$result_code" 1
      [[ ! -s "$fixture/output" ]]
      z.t.expect.status.is.true

      z.dir.not.exists "$work_dir"
      z.t.expect.status.is.true

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "modの比較に失敗した場合"; {
    z.t.it "状態を表示せず作業directoryを片付ける"; {
      local fixture=$(mktemp -d /tmp/z_mod_list.XXXXXX)
      local z_root="$fixture/installed"
      local work_dir="$fixture/work"
      z.dir.make path="$fixture/source/example"
      z.dir.make path="$z_root/mod/example"
      z.t.mock name=mktemp behavior="z.dir.make path=\"$work_dir\"; z.io \"$work_dir\""
      z.t.mock name="z.install.mod._fetch" behavior="z.return \"$fixture/source\""
      z.t.mock name=diff behavior="return 2"

      z.install.mod.list > "$fixture/output" 2>/dev/null
      local result_code=$?

      z.t.expect "$result_code" 1
      [[ ! -s "$fixture/output" ]]
      z.t.expect.status.is.true

      z.dir.not.exists "$work_dir"
      z.t.expect.status.is.true

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "作業directoryを確保できない場合"; {
    z.t.it "取得を開始せず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_list.XXXXXX)
      local -a fetched=()
      z.t.mock name=mktemp behavior="return 1"
      z.t.mock name="z.install.mod._fetch" behavior='fetched+=(called); return 0'

      z.install.mod.list > "$fixture/output" 2>/dev/null
      local result_code=$?

      z.t.expect "$result_code" 1 skip_unmock=true
      z.t.expect "$fetched" ""

      z.dir.remove path="$fixture"
    }
  }
}

z.t.describe "z.install.mod._fetch"; {
  z.t.context "配布archiveを取得できる場合"; {
    z.t.it "指定branchを一度取得してmod配布元を返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/z-topic/mod/example"
      z.dir.make path="$fixture/work"
      z.file.write path="$fixture/input/z-topic/mod/example/value" content=remote
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" z-topic

      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod._fetch dir="$fixture/work" branch=topic/change
      local result_code=$?
      local source_dir=$REPLY

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$source_dir" "$fixture/work/z-topic/mod"
      z.t.expect "$call" "-fLsS https://github.com/milkeclair/z/archive/refs/heads/topic/change.tar.gz -o $fixture/work/source.tar.gz"

      z.file.read path="$source_dir/example/value"
      z.t.expect.reply remote

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "取得に失敗した場合"; {
    z.t.it "展開を行わず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      local -a extracted=()
      z.t.mock name=curl behavior="return 22"
      z.t.mock name=tar behavior='extracted+=(called); return 0'

      z.install.mod._fetch dir="$fixture" 2>/dev/null
      local result_code=$?

      z.t.expect "$result_code" 1 skip_unmock=true
      z.t.expect "$extracted" ""

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "archiveが壊れている場合"; {
    z.t.it "失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.t.mock name=curl behavior="z.file.write path=\"$fixture/source.tar.gz\" content=invalid"

      z.install.mod._fetch dir="$fixture" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "mod directoryが含まれない場合"; {
    z.t.it "一覧を空として扱わず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/z-main/lib"
      z.dir.make path="$fixture/work"
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" z-main
      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod._fetch dir="$fixture/work" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "配布元directoryが複数ある場合"; {
    z.t.it "任意の配布元を選ばず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/one/mod"
      z.dir.make path="$fixture/input/two/mod"
      z.dir.make path="$fixture/work"
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" one two
      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod._fetch dir="$fixture/work" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }
}
