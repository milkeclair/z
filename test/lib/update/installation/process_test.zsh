source "$z_main"

z.t.describe "z.update.installation._replace"; {
  z.t.context "oldとpreparedがある場合"; {
    z.t.it "preparedへ切り替えてoldをbackupに残す"; {
      local dir="/tmp/z_t/update_replace/with space"
      z.dir.remove path=/tmp/z_t/update_replace
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/value" content=old
      z.file.write path="$dir/prepared/value" content=new

      z.update.installation._replace dir="$dir/current" prepared="$dir/prepared" backup="$dir/previous"
      local replace_status=$?
      local result=$REPLY

      z.t.expect "$replace_status" 0
      REPLY=$result
      z.t.expect.reply.is.null

      z.file.read path="$dir/current/value"
      z.t.expect.reply new

      z.file.read path="$dir/previous/value"
      z.t.expect.reply old

      z.dir.not.exists "$dir/prepared"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "必須引数が欠ける場合"; {
    z.t.it "mvを実行しない"; {
      z.t.mock name=mv

      z.update.installation._replace prepared=/tmp/prepared backup=/tmp/previous
      local missing_dir=$?

      z.update.installation._replace dir=/tmp/current backup=/tmp/previous
      local missing_prepared=$?

      z.update.installation._replace dir=/tmp/current prepared=/tmp/prepared
      local missing_backup=$?

      z.t.mock.result name=mv
      local call=$REPLY

      z.t.expect "$missing_dir" 1
      z.t.expect "$missing_prepared" 1
      z.t.expect "$missing_backup" 1
      REPLY=$call
      z.t.expect.reply.is.null
    }
  }

  z.t.context "backup pathがすでにある場合"; {
    z.t.it "oldもbackupも変更しない"; {
      local dir=/tmp/z_t/update_replace/existing
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/prepared"
      z.dir.make path="$dir/previous"
      z.file.write path="$dir/current/value" content=old
      z.file.write path="$dir/previous/value" content=keep

      z.update.installation._replace dir="$dir/current" prepared="$dir/prepared" backup="$dir/previous"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.file.read path="$dir/current/value"
      z.t.expect.reply old

      z.file.read path="$dir/previous/value"
      z.t.expect.reply keep

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "最初のmvが失敗した場合"; {
    z.t.it "oldを残す"; {
      local dir=/tmp/z_t/update_replace/first_failure
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/value" content=old

      z.t.mock name=mv behavior="return 1"

      z.update.installation._replace dir="$dir/current" prepared="$dir/prepared" backup="$dir/previous"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.file.read path="$dir/current/value"
      z.t.expect.reply old

      z.dir.not.exists "$dir/previous"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "preparedへの切り替えが失敗した場合"; {
    z.t.it "backupからoldへ戻す"; {
      local dir=/tmp/z_t/update_replace/second_failure
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/value" content=old
      z.file.write path="$dir/prepared/value" content=new

      z.t.mock name=mv behavior="
        if z.is.eq \"\$1\" \"$dir/prepared\"; then return 1; fi
        command mv \"\$@\"
      "

      z.update.installation._replace dir="$dir/current" prepared="$dir/prepared" backup="$dir/previous"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.file.read path="$dir/current/value"
      z.t.expect.reply old

      z.file.read path="$dir/prepared/value"
      z.t.expect.reply new

      z.dir.not.exists "$dir/previous"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "切り替えと復元が両方失敗した場合"; {
    z.t.it "backupを残し復元先を通知する"; {
      local dir=/tmp/z_t/update_replace/restore_failure
      z.dir.make path="$dir/current"
      z.dir.make path="$dir/prepared"
      z.file.write path="$dir/current/value" content=old

      z.t.mock name=mv behavior="
        if z.is.eq \"\$1\" \"$dir/prepared\" || z.is.eq \"\$1\" \"$dir/previous\"; then return 1; fi
        command mv \"\$@\"
      "

      z.update.installation._replace dir="$dir/current" prepared="$dir/prepared" backup="$dir/previous" 2>"$dir/error"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.dir.not.exists "$dir/current"
      z.t.expect.status.is.true

      z.file.read path="$dir/previous/value"
      z.t.expect.reply old

      z.file.read path="$dir/error"
      z.t.expect.includes "$REPLY" "$dir/previous"

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "oldとpreparedが同じ場合"; {
    z.t.it "移動しない"; {
      local dir=/tmp/z_t/update_replace/same
      z.dir.make path="$dir/current"
      z.file.write path="$dir/current/value" content=old

      z.update.installation._replace dir="$dir/current" prepared="$dir/current" backup="$dir/previous"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.file.read path="$dir/current/value"
      z.t.expect.reply old

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

  z.t.context "preparedが存在しない場合"; {
    z.t.it "oldを移動しない"; {
      local dir=/tmp/z_t/update_replace/missing_prepared
      z.dir.make path="$dir/current"
      z.file.write path="$dir/current/value" content=old

      z.update.installation._replace dir="$dir/current" prepared="$dir/missing" backup="$dir/previous"
      local replace_status=$?

      z.t.expect "$replace_status" 1

      z.file.read path="$dir/current/value"
      z.t.expect.reply old

      z.dir.not.exists "$dir/previous"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_replace
    }
  }

}

z.t.describe "z.update.installation._reload"; {
  z.t.context "updated mainを読み直す場合"; {
    z.t.it "cancel・source・enableの順に実行する"; {
      local dir="/tmp/z_t/update_reload/with space"
      z.dir.remove path=/tmp/z_t/update_reload
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content="print -r -- load >> \"$dir/events\"; print -rn -- \"\$Z_ROOT\" > \"$dir/loaded_root\""

      z.t.mock name="z.completion.cache._cancel" behavior="print -r -- cancel >> \"$dir/events\""
      z.t.mock name="z.completion.enable" behavior="print -r -- enable >> \"$dir/events\""

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir"
      }
      local reload_status=$?
      local result=$REPLY

      z.t.expect "$reload_status" 0
      REPLY=$result
      z.t.expect.reply.is.null

      z.file.read path="$dir/events"
      z.t.expect.reply $'cancel\nload\nenable'

      z.file.read path="$dir/loaded_root"
      z.t.expect.reply "$dir"

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "dir引数がない場合"; {
    z.t.it "失敗する"; {
      z.update.installation._reload

      z.t.expect.status.is.false
    }
  }

  z.t.context "mainが存在しない場合"; {
    z.t.it "sourceしない"; {
      z.update.installation._reload dir=/tmp/z_t/update_reload_missing

      z.t.expect.status.is.false
    }
  }

  z.t.context "補完jobが回収済みの場合"; {
    z.t.it "IDを破棄して本体の再読込を続ける"; {
      local dir=/tmp/z_t/update_reload/collected_job
      local z_completion_cache_job_id=collected-job
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content="touch \"$dir/loaded\""

      z.t.mock name="z.job.status" behavior="return 1"
      z.t.mock name="z.completion.enable" behavior="return 0"

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir"
      }
      local reload_status=$?
      local remaining_id=$z_completion_cache_job_id

      z.t.expect "$reload_status" 0
      z.t.expect.is.null "$remaining_id"

      z.file.exists "$dir/loaded"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "sourceが失敗した場合"; {
    z.t.it "enableを実行しない"; {
      local dir=/tmp/z_t/update_reload/source_failure
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content="return 7"

      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable"

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir"
      }
      local reload_status=$?

      z.t.mock.result name="z.completion.enable"
      local call=$REPLY

      z.t.expect "$reload_status" 1
      REPLY=$call
      z.t.expect.reply.is.null

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "enableが失敗した場合"; {
    z.t.it "失敗を呼び出し元へ返す"; {
      local dir=/tmp/z_t/update_reload/enable_failure
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content=":"

      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable" behavior="return 1"

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir"
      }
      local reload_status=$?

      z.t.expect "$reload_status" 1

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "previousがインストール先の中の場合"; {
    z.t.it "同じ相対位置へ移動する"; {
      local dir=/tmp/z_t/update_reload/cwd
      local original_dir=$PWD
      z.dir.make path="$dir/lib"
      z.file.write path="$dir/main.zsh" content=":"

      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable" behavior="return 0"

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir" previous="$dir/lib"
        local reload_status=$?

        z.path.current
        local reloaded_dir=$REPLY
        cd "$original_dir"
        z.file.write path="$dir/cwd" content="$reloaded_dir"
        return $reload_status
      }
      local reload_status=$?

      z.t.expect "$reload_status" 0

      z.file.read path="$dir/cwd"
      z.t.expect.reply "$dir/lib"

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "previousの子directoryがなくなった場合"; {
    z.t.it "新しいインストール先へ戻る"; {
      local dir=/tmp/z_t/update_reload/fallback
      local original_dir=$PWD
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content=":"

      z.t.mock name="z.completion.cache._cancel" behavior="return 0"
      z.t.mock name="z.completion.enable" behavior="return 0"

      () {
        local Z_ROOT=$z_root

        z.update.installation._reload dir="$dir" previous="$dir/removed"
        local reload_status=$?

        z.path.current
        local reloaded_dir=$REPLY
        cd "$original_dir"
        z.file.write path="$dir/cwd" content="$reloaded_dir"
        return $reload_status
      }
      local reload_status=$?

      z.t.expect "$reload_status" 0

      z.file.read path="$dir/cwd"
      z.t.expect.reply "$dir"

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

  z.t.context "completion関数がない場合"; {
    z.t.it "本体だけを読み直す"; {
      local dir=/tmp/z_t/update_reload/no_completion
      z.dir.make path="$dir"
      z.file.write path="$dir/main.zsh" content="touch \"$dir/loaded\""

      (
        unfunction z.completion.cache._cancel z.completion.enable

        z.update.installation._reload dir="$dir"
      )
      local reload_status=$?

      z.t.expect "$reload_status" 0

      z.file.exists "$dir/loaded"
      z.t.expect.status.is.true

      z.dir.remove path=/tmp/z_t/update_reload
    }
  }

}

