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
      z.t.mock name="z.install.mod._fetch" behavior="((fetch_calls++)); REPLY=\"$fixture/source\""

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
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""

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
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""

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
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
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

z.t.describe "z.install.mod.all"; {
  z.t.context "配布元の全modを導入する場合"; {
    z.t.it "一度の取得で更新・追加を行い独自modを保持する"; {
      local fixture=$(mktemp -d "/tmp/z all command.XXXXXX")
      local z_root="$fixture/installed"
      local Z_INSTALL_BRANCH=topic/change
      local all_fetch_count=0
      local all_confirm_count=0
      z.dir.make path="$z_root/mod/app"
      z.dir.make path="$z_root/mod/custom"
      z.dir.make path="$fixture/source/app"
      z.dir.make path="$fixture/source/new"
      z.file.write path="$z_root/main.zsh" content="touch \"$fixture/reloaded\""
      z.file.write path="$z_root/mod/app/value" content=old
      z.file.write path="$z_root/mod/custom/value" content=custom
      z.file.write path="$fixture/source/app/value" content=updated
      z.file.write path="$fixture/source/new/value" content=added
      z.t.mock name="z.install.mod._fetch" behavior="((all_fetch_count++)); REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="((all_confirm_count++)); return 0"
      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable" behavior="return 0"

      () {
        local Z_ROOT=$z_root
        z.install.mod.all > "$fixture/output"
      }
      local result_code=$?
      local fetch_count=$all_fetch_count
      local confirm_count=$all_confirm_count

      z.t.expect "$result_code" 0
      z.t.expect "$fetch_count" 1
      z.t.expect "$confirm_count" 1
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply updated
      z.file.read path="$z_root/mod/new/value"
      z.t.expect.reply added
      z.file.read path="$z_root/mod/custom/value"
      z.t.expect.reply custom
      z.file.exists "$fixture/reloaded"
      z.t.expect.status.is.true
      local leftovers=("$z_root"/.z-mod-all.*(N/))
      z.t.expect "${#leftovers}" 0

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "確認を中止した場合"; {
    z.t.it "現行modを維持して作業領域を除去する"; {
      local fixture=$(mktemp -d /tmp/z_all_command.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$z_root/mod/app"
      z.dir.make path="$fixture/source/app"
      z.file.write path="$z_root/main.zsh" content=":"
      z.file.write path="$z_root/mod/app/value" content=old
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="return 1"

      z.install.mod.all > "$fixture/output"

      z.t.expect.status.is.false
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply old
      local leftovers=("$z_root"/.z-mod-all.*(N/))
      z.t.expect "${#leftovers}" 0

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "コピーが失敗する場合"; {
    z.t.it "現行modを維持して作業領域を除去する"; {
      local fixture=$(mktemp -d /tmp/z_all_command.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$z_root/mod/app"
      z.dir.make path="$fixture/source/app"
      z.file.write path="$z_root/main.zsh" content=":"
      z.file.write path="$z_root/mod/app/value" content=old
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="return 0"
      z.t.mock name=cp behavior="return 1"

      z.install.mod.all > "$fixture/output"

      z.t.expect.status.is.false
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply old
      local leftovers=("$z_root"/.z-mod-all.*(N/))
      z.t.expect "${#leftovers}" 0

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "再読込に失敗する場合"; {
    z.t.it "旧modを復旧用に残す"; {
      local fixture=$(mktemp -d /tmp/z_all_command.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$z_root/mod/app"
      z.dir.make path="$fixture/source/app"
      z.file.write path="$z_root/main.zsh" content="return 7"
      z.file.write path="$z_root/mod/app/value" content=old
      z.file.write path="$fixture/source/app/value" content=updated
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="return 0"
      z.t.mock name="z.completion.cache._cancel" behavior="return 0"

      () {
        local Z_ROOT=$z_root
        z.install.mod.all > "$fixture/output" 2>/dev/null
      }
      local result_code=$?
      local leftovers=("$z_root"/.z-mod-all.*(N/))

      z.t.expect "$result_code" 1
      z.t.expect "${#leftovers}" 1
      z.file.read path="$leftovers[1]/previous/app/value"
      z.t.expect.reply old
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply updated

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "配布元にmodがない場合"; {
    z.t.it "確認を行わず成功しREPLYを空にする"; {
      local fixture=$(mktemp -d /tmp/z_all_empty.XXXXXX)
      local z_root="$fixture/installed"
      local all_confirm_count=0
      z.dir.make path="$z_root/mod/custom"
      z.dir.make path="$fixture/source"
      z.file.write path="$z_root/main.zsh" content=":"
      z.file.write path="$z_root/mod/custom/value" content=custom
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="((all_confirm_count++)); return 1"

      z.install.mod.all > "$fixture/output"
      local result_code=$?
      local result_reply=$REPLY
      local calls=$all_confirm_count

      z.t.expect "$result_code" 0
      z.t.expect "$result_reply" ""
      z.t.expect "$calls" 0
      z.file.read path="$z_root/mod/custom/value"
      z.t.expect.reply custom

      z.dir.remove path="$fixture"
    }
  }
  z.t.context "作業領域の作成に失敗した場合"; {
    z.t.it "取得前に中断して現行modを維持する"; {
      local fixture=$(mktemp -d /tmp/z_all_command.XXXXXX)
      local z_root="$fixture/installed"
      local -a all_fetch_attempts=()
      z.dir.make path="$z_root/mod/app"
      z.file.write path="$z_root/main.zsh" content=":"
      z.file.write path="$z_root/mod/app/value" content=old
      z.t.mock name=mktemp behavior="return 1"
      z.t.mock name="z.install.mod._fetch" behavior='all_fetch_attempts+=(called); return 0'

      z.install.mod.all > "$fixture/output"
      local result_code=$?
      local attempts="$all_fetch_attempts"

      z.t.expect "$result_code" 1
      z.t.expect "$attempts" ""
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "導入先の情報がない場合"; {
    z.t.it "失敗する"; {
      local z_root=""

      z.install.mod.all

      z.t.expect.status.is.false
    }
  }
  z.t.context "補完の有効化だけが失敗した場合"; {
    z.t.it "導入成功として更新しbackupを片付ける"; {
      local fixture=$(mktemp -d /tmp/z_all_command.XXXXXX)
      local z_root="$fixture/installed"
      z.dir.make path="$z_root/mod/app"
      z.dir.make path="$fixture/source/app"
      z.file.write path="$z_root/main.zsh" content=":"
      z.file.write path="$z_root/mod/app/value" content=old
      z.file.write path="$fixture/source/app/value" content=new
      z.t.mock name="z.install.mod._fetch" behavior="REPLY=\"$fixture/source\""
      z.t.mock name="z.install.mod.all._confirm" behavior="return 0"
      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable" behavior="return 1"

      () {
        local Z_ROOT=$z_root

        z.install.mod.all > "$fixture/output"
      }
      local result_code=$?
      local leftovers=("$z_root"/.z-mod-all.*(N/))

      z.t.expect "$result_code" 0
      z.t.expect "${#leftovers}" 0
      z.file.read path="$z_root/mod/app/value"
      z.t.expect.reply new

      z.dir.remove path="$fixture"
    }
  }
}
