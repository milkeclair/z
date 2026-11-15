source "$z_main"

z.t.describe "z.install.mod.all._confirm"; {
  z.t.context "yまたはYの場合"; {
    z.t.it "承諾する"; {
      for answer in y Y; do
        z.install.mod.all._confirm dir=/tmp/example <<< "$answer" >/dev/null

        z.t.expect.status.is.true
      done
    }
  }

  z.t.context "nまたはEOFの場合"; {
    z.t.it "中止する"; {
      z.install.mod.all._confirm dir=/tmp/example <<< n >/dev/null
      z.t.expect.status.is.false

      z.install.mod.all._confirm dir=/tmp/example </dev/null >/dev/null
      z.t.expect.status.is.false
    }
  }

  z.t.context "dirが未指定の場合"; {
    z.t.it "入力を読まず失敗する"; {
      z.install.mod.all._confirm <<< y >/dev/null # zls: ignore

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.install.mod.all._prepare"; {
  z.t.context "現行modと独自データがある場合"; {
    z.t.it "配布元を更新し独自modと設定を維持する"; {
      local fixture=$(mktemp -d "/tmp/z all prepare.XXXXXX")
      z.dir.make path="$fixture/source/app"
      z.dir.make path="$fixture/source/new"
      z.dir.make path="$fixture/current/app"
      z.dir.make path="$fixture/current/custom"
      z.file.write path="$fixture/source/app/value" content=new
      z.file.write path="$fixture/source/new/value" content=added
      z.file.write path="$fixture/current/app/value" content=old
      z.file.write path="$fixture/current/app/removed" content=obsolete
      z.file.write path="$fixture/current/custom/value" content=custom
      z.file.write path="$fixture/current/.settings" content=settings

      z.install.mod.all._prepare source="$fixture/source" current="$fixture/current" dir="$fixture/next"
      local result_code=$?

      z.t.expect "$result_code" 0
      z.file.read path="$fixture/next/app/value"
      z.t.expect.reply new
      z.file.read path="$fixture/next/new/value"
      z.t.expect.reply added
      z.file.read path="$fixture/next/custom/value"
      z.t.expect.reply custom
      z.file.read path="$fixture/next/.settings"
      z.t.expect.reply settings
      z.file.not.exists "$fixture/next/app/removed"
      z.t.expect.status.is.true
      z.file.read path="$fixture/current/app/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "現行modがない場合"; {
    z.t.it "配布元だけで準備する"; {
      local fixture=$(mktemp -d /tmp/z_all_prepare.XXXXXX)
      z.dir.make path="$fixture/source/app"
      z.file.write path="$fixture/source/app/value" content=new

      z.install.mod.all._prepare source="$fixture/source" current="$fixture/current" dir="$fixture/next"

      z.t.expect.status.is.true
      z.file.read path="$fixture/next/app/value"
      z.t.expect.reply new

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "コピーに失敗した場合"; {
    z.t.it "現行modを維持して失敗する"; {
      local fixture=$(mktemp -d /tmp/z_all_prepare.XXXXXX)
      z.dir.make path="$fixture/source/app"
      z.dir.make path="$fixture/current/app"
      z.file.write path="$fixture/current/app/value" content=old
      z.t.mock name=cp behavior="return 1"

      z.install.mod.all._prepare source="$fixture/source" current="$fixture/current" dir="$fixture/next"

      z.t.expect.status.is.false
      z.file.read path="$fixture/current/app/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "sourceがない場合"; {
    z.t.it "準備先を作らず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_all_prepare.XXXXXX)

      z.install.mod.all._prepare current="$fixture/current" dir="$fixture/next" # zls: ignore

      z.t.expect.status.is.false
      z.dir.not.exists "$fixture/next"
      z.t.expect.status.is.true

      z.dir.remove path="$fixture"
    }
  }
}

z.t.describe "z.install.mod.all._replace"; {
  z.t.context "現行modがある場合"; {
    z.t.it "切り替えて旧modをbackupに残す"; {
      local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
      z.dir.make path="$fixture/current"
      z.dir.make path="$fixture/next"
      z.file.write path="$fixture/current/value" content=old
      z.file.write path="$fixture/next/value" content=new

      z.install.mod.all._replace current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous"

      z.t.expect.status.is.true
      z.file.read path="$fixture/current/value"
      z.t.expect.reply new
      z.file.read path="$fixture/previous/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "現行modがない場合"; {
    z.t.it "初回導入する"; {
      local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
      z.dir.make path="$fixture/next"
      z.file.write path="$fixture/next/value" content=new

      z.install.mod.all._replace current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous"

      z.t.expect.status.is.true
      z.file.read path="$fixture/current/value"
      z.t.expect.reply new
      z.dir.not.exists "$fixture/previous"
      z.t.expect.status.is.true

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "切替に失敗した場合"; {
    z.t.it "旧modへ復元する"; {
      local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
      local moves=0
      z.dir.make path="$fixture/current"
      z.dir.make path="$fixture/next"
      z.file.write path="$fixture/current/value" content=old
      z.t.mock name=mv behavior='
        ((moves++))
        if z.int.is.eq $moves 2; then
          return 1
        fi
        command mv "$@"
      '

      z.install.mod.all._replace current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous"
      local result_code=$?
      local move_count=$moves

      z.t.expect "$result_code" 1
      z.t.expect "$move_count" 3
      z.file.read path="$fixture/current/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "復元にも失敗した場合"; {
    z.t.it "backupを残す"; {
      local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
      local moves=0
      z.dir.make path="$fixture/current"
      z.dir.make path="$fixture/next"
      z.file.write path="$fixture/current/value" content=old
      z.t.mock name=mv behavior='
        ((moves++))
        if z.int.is.gt $moves 1; then
          return 1
        fi
        command mv "$@"
      '

      z.install.mod.all._replace current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous" 2>/dev/null

      z.t.expect.status.is.false
      z.file.read path="$fixture/previous/value"
      z.t.expect.reply old

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "必須引数が不足する場合"; {
    z.t.it "現行modを変更しない"; {
      for missing in current prepared backup; do
        local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
        z.dir.make path="$fixture/current"
        z.dir.make path="$fixture/next"
        z.file.write path="$fixture/current/value" content=old
        z.arg.named.shift "$missing" current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous"
        local args=(${(@)REPLY})

        z.install.mod.all._replace "${args[@]}" 2>/dev/null

        z.t.expect.status.is.false
        z.file.read path="$fixture/current/value"
        z.t.expect.reply old

        z.dir.remove path="$fixture"
      done
    }
  }

  z.t.context "backupがすでにある場合"; {
    z.t.it "現行modとbackupを変更しない"; {
      local fixture=$(mktemp -d /tmp/z_all_replace.XXXXXX)
      z.dir.make path="$fixture/current"
      z.dir.make path="$fixture/next"
      z.dir.make path="$fixture/previous"
      z.file.write path="$fixture/current/value" content=old
      z.file.write path="$fixture/previous/value" content=backup

      z.install.mod.all._replace current="$fixture/current" prepared="$fixture/next" backup="$fixture/previous"

      z.t.expect.status.is.false
      z.file.read path="$fixture/current/value"
      z.t.expect.reply old
      z.file.read path="$fixture/previous/value"
      z.t.expect.reply backup

      z.dir.remove path="$fixture"
    }
  }
}

z.t.describe "z.install.mod.all._reload"; {
  z.t.context "mainを再読込する場合"; {
    z.t.it "sourceの後に補完を有効化する"; {
      local fixture=$(mktemp -d /tmp/z_all_reload.XXXXXX)
      z.file.write path="$fixture/main.zsh" content="print -r -- load > \"$fixture/events\"; print -rn -- \"\$Z_ROOT\" > \"$fixture/root\""
      z.t.mock name="z.completion.enable" behavior="print -r -- enable >> \"$fixture/events\""

      () {
        local Z_ROOT=$z_root
        z.install.mod.all._reload dir="$fixture"
      }
      local result_code=$?

      z.t.expect "$result_code" 0
      z.file.read path="$fixture/events"
      z.t.expect.reply $'load\nenable'
      z.file.read path="$fixture/root"
      z.t.expect.reply "$fixture"

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "sourceが失敗する場合"; {
    z.t.it "補完を有効化せず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_all_reload.XXXXXX)
      local enabled=0
      z.file.write path="$fixture/main.zsh" content="return 7"
      z.t.mock name="z.completion.enable" behavior="((enabled++)); return 0"

      () {
        local Z_ROOT=$z_root
        z.install.mod.all._reload dir="$fixture"
      }
      local result_code=$?
      local calls=$enabled

      z.t.expect "$result_code" 1
      z.t.expect "$calls" 0

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "作業directoryが更新対象mod内の場合"; {
    z.t.it "同じ相対位置か導入先へ戻る"; {
      for subdir in nested removed; do
        local fixture=$(mktemp -d /tmp/z_all_reload.XXXXXX)
        local original_dir=$PWD
        z.dir.make path="$fixture/mod/app/nested"
        z.file.write path="$fixture/main.zsh" content=":"
        z.t.mock name="z.completion.enable" behavior="return 0"

        () {
          local Z_ROOT=$z_root
          z.install.mod.all._reload dir="$fixture" previous="$fixture/mod/app/$subdir"
          local result_code=$?
          z.file.write path="$fixture/cwd" content="$PWD"
          cd "$original_dir"
          return $result_code
        }
        local result_code=$?

        z.t.expect "$result_code" 0
        z.file.read path="$fixture/cwd"
        if z.is.eq "$subdir" nested; then
          z.t.expect.reply "$fixture/mod/app/nested"
        else
          z.t.expect.reply "$fixture"
        fi

        z.dir.remove path="$fixture"
      done
    }
  }

  z.t.context "補完の有効化が失敗する場合"; {
    z.t.it "再読込後の失敗を返す"; {
      local fixture=$(mktemp -d /tmp/z_all_reload.XXXXXX)
      z.file.write path="$fixture/main.zsh" content=":"
      z.t.mock name="z.completion.enable" behavior="return 1"

      () {
        local Z_ROOT=$z_root
        z.install.mod.all._reload dir="$fixture"
      }

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "dirが未指定の場合"; {
    z.t.it "失敗する"; {
      z.install.mod.all._reload 2>/dev/null # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
