source "$z_main"

z.t.describe "z.update"; {
  z.t.context "各処理が成功する場合"; {
    z.t.it "値を次の処理へ渡し順番に実行して後始末する"; {
      local dir=/tmp/z_t/update_flow/success
      z.dir.remove path=/tmp/z_t/update_flow
      z.dir.make path="$dir/installed/lib"
      z.dir.make path="$dir/installed/mod/completion"
      z.file.write path="$dir/installed/main.zsh" content=old

      z.t.mock name=mktemp behavior="z.dir.make path=\"$dir/.z-update.fixture\"; z.io \"$dir/.z-update.fixture\""
      z.t.mock name="z.update._confirm" behavior="return 0"
      z.t.mock name="z.update.archive._download" behavior="print download >> \"$dir/events\"; REPLY=\"$dir/source.tar.gz\""
      z.t.mock name="z.update.archive._extract" behavior="print extract >> \"$dir/events\"; REPLY=\"$dir/source\""
      z.t.mock name="z.update.mod._resolve" behavior="print resolve >> \"$dir/events\"; REPLY=(\"job\" \"completion\")"
      z.t.mock name="z.update.core._copy" behavior="print core >> \"$dir/events\""
      z.t.mock name="z.update.mod._copy" behavior="print mods >> \"$dir/events\""
      z.t.mock name="z.update.installation._replace" behavior="print replace >> \"$dir/events\""
      z.t.mock name="z.update.installation._reload" behavior="print reload >> \"$dir/events\""

      () {
        local z_root="$dir/installed"
        z.update
      }
      local update_status=$?
      local result=$REPLY

      z.t.mock.result name="z.update.mod._copy"
      local mod_call=$REPLY

      z.t.mock.result name="z.update.archive._download"
      local download_call=$REPLY

      z.file.read path="$dir/events"
      local events=$REPLY

      z.t.expect "$update_status" 0
      REPLY=$result
      z.t.expect.reply.is.null
      z.t.expect "$events" $'download\nextract\nresolve\ncore\nmods\nreplace\nreload'
      z.t.expect "$mod_call" "source=$dir/source current=$dir/installed dir=$dir/.z-update.fixture/next job completion"
      z.t.expect "$download_call" "dir=$dir/.z-update.fixture branch=main"

      z.dir.not.exists "$dir/.z-update.fixture"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_flow
    }
  }

  z.t.context "引数を指定した場合"; {
    z.t.it "処理を開始しない"; {
      z.t.mock name="z.update._confirm"
      z.update unexpected
      local update_status=$?

      z.t.mock.result name="z.update._confirm"
      local call=$REPLY

      z.t.expect "$update_status" 1
      REPLY=$call

      z.t.expect.reply.is.null
    }
  }

  z.t.context "インストール先が不正な場合"; {
    z.t.it "確認入力へ進まない"; {
      z.t.mock name="z.update._confirm"

      () {
        local z_root=/tmp/z_t/update_flow_absent
        z.update
      }
      local update_status=$?

      z.t.mock.result name="z.update._confirm"
      local call=$REPLY

      z.t.expect "$update_status" 1
      REPLY=$call
      z.t.expect.reply.is.null
    }
  }

  z.t.context "確認をキャンセルした場合"; {
    z.t.it "取得処理を開始しない"; {
      local dir=/tmp/z_t/update_flow/cancel
      z.dir.make path="$dir/installed/lib"
      z.file.write path="$dir/installed/main.zsh" content=old

      z.t.mock name="z.update._confirm" behavior="return 1"
      z.t.mock name="z.update.archive._download"

      () {
        local z_root="$dir/installed"
        z.update
      }
      local update_status=$?

      z.t.mock.result name="z.update.archive._download"
      local call=$REPLY

      z.t.expect "$update_status" 1
      REPLY=$call
      z.t.expect.reply.is.null

      local work_dirs=("$dir"/.z-update.*(N/))
      z.t.expect "${#work_dirs}" 0

      z.dir.remove path=/tmp/z_t/update_flow
    }
  }

  z.t.context "作業directoryを確保できない場合"; {
    z.t.it "取得処理へ進まず失敗する"; {
      local dir=/tmp/z_t/update_flow/work_failure
      z.dir.make path="$dir/installed/lib"
      z.file.write path="$dir/installed/main.zsh" content=old

      z.t.mock name="z.update._confirm" behavior="return 0"
      z.t.mock name=mktemp behavior="return 1"
      z.t.mock name="z.update.archive._download"

      () {
        local z_root="$dir/installed"
        z.update
      }
      local update_status=$?

      z.t.mock.result name="z.update.archive._download"
      local call=$REPLY

      z.t.expect "$update_status" 1
      REPLY=$call
      z.t.expect.reply.is.null

      z.file.read path="$dir/installed/main.zsh"
      z.t.expect.reply old

      z.dir.remove path=/tmp/z_t/update_flow
    }
  }

  z.t.context "途中の取得処理が失敗した場合"; {
    z.t.it "次の処理へ進まず作業directoryを除去する"; {
      local dir=/tmp/z_t/update_flow/download_failure
      z.dir.make path="$dir/installed/lib"
      z.file.write path="$dir/installed/main.zsh" content=old

      z.t.mock name=mktemp behavior="z.dir.make path=\"$dir/.z-update.fixture\"; z.io \"$dir/.z-update.fixture\""
      z.t.mock name="z.update._confirm" behavior="return 0"
      z.t.mock name="z.update.archive._download" behavior="return 1"
      z.t.mock name="z.update.archive._extract"

      () {
        local z_root="$dir/installed"
        z.update
      }
      local update_status=$?

      z.t.mock.result name="z.update.archive._extract"
      local call=$REPLY

      z.t.expect "$update_status" 1
      REPLY=$call
      z.t.expect.reply.is.null

      z.dir.not.exists "$dir/.z-update.fixture"
      z.t.expect.status.is.true

      z.file.read path="$dir/installed/main.zsh"
      z.t.expect.reply old

      z.dir.remove path=/tmp/z_t/update_flow
    }
  }

  z.t.context "切り替え後の再読込に失敗した場合"; {
    z.t.it "復旧用backupを後始末で削除しない"; {
      local dir=/tmp/z_t/update_flow/reload_failure
      z.dir.make path="$dir/installed/lib"
      z.file.write path="$dir/installed/main.zsh" content=main

      z.t.mock name=mktemp behavior="z.dir.make path=\"$dir/.z-update.fixture\"; z.io \"$dir/.z-update.fixture\""
      z.t.mock name="z.update._confirm" behavior="return 0"
      z.t.mock name="z.update.archive._download" behavior="REPLY=\"$dir/archive.tar.gz\""
      z.t.mock name="z.update.archive._extract" behavior="REPLY=\"$dir/source\""
      z.t.mock name="z.update.mod._resolve" behavior="REPLY=\"\""
      z.t.mock name="z.update.core._copy" behavior="return 0"
      z.t.mock name="z.update.mod._copy" behavior="return 0"
      z.t.mock name="z.update.installation._replace" behavior="z.dir.make path=\"$dir/.z-update.fixture/previous\"; z.file.write path=\"$dir/.z-update.fixture/previous/main.zsh\" content=old"
      z.t.mock name="z.update.installation._reload" behavior="return 1"

      () {
        local z_root="$dir/installed"
        z.update
      } 2>"$dir/error"
      local update_status=$?

      z.t.expect "$update_status" 1

      z.file.read path="$dir/.z-update.fixture/previous/main.zsh"
      z.t.expect.reply old

      z.file.read path="$dir/error"
      z.t.expect.includes "$REPLY" "$dir/.z-update.fixture/previous"

      z.dir.remove path=/tmp/z_t/update_flow
    }
  }

}

z.t.describe "z.update._confirm"; {
  z.t.context "yを入力した場合"; {
    z.t.it "確認先を表示して成功する"; {
      local dir=/tmp/z_t/update_confirm
      z.dir.make path="$dir"

      z.update._confirm dir="/tmp/installed z" <<<'y' >"$dir/prompt"
      local confirm_status=$?
      local result=$REPLY

      z.t.expect "$confirm_status" 0
      REPLY=$result
      z.t.expect.reply.is.null

      z.file.read path="$dir/prompt"
      z.t.expect.includes "$REPLY" "Update /tmp/installed z and its installed mods? (y/n):"

      z.dir.remove path="$dir"
    }
  }

  z.t.context "Yを入力した場合"; {
    z.t.it "成功する"; {
      z.t.mock name="z.io.read" behavior="REPLY=Y"

      z.update._confirm dir=/tmp/installed >/dev/null

      z.t.expect.status.is.true
    }
  }

  z.t.context "nを入力した場合"; {
    z.t.it "失敗してREPLYを空にする"; {
      z.t.mock name="z.io.read" behavior="REPLY=n"

      z.update._confirm dir=/tmp/installed >/dev/null
      local confirm_status=$?
      local result=$REPLY

      z.t.expect "$confirm_status" 1
      REPLY=$result
      z.t.expect.reply.is.null
    }
  }

  z.t.context "入力がEOFの場合"; {
    z.t.it "確認済みとして扱わない"; {
      z.update._confirm dir=/tmp/installed </dev/null >/dev/null

      z.t.expect.status.is.false
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "入力を読まない"; {
      z.t.mock name="z.io.read"

      z.update._confirm >/dev/null # zls: ignore missing-named-argument
      local confirm_status=$?

      z.t.mock.result name="z.io.read"
      local call=$REPLY

      z.t.expect "$confirm_status" 1
      REPLY=$call
      z.t.expect.reply.is.null
    }
  }

}

