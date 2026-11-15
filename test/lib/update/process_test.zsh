source "$z_main"

# prepare an old installation and a local branch archive for update tests
#
# REPLY: fixture directory
# return: 0|1
z_update_test_fixture() {
  local fixture=$(mktemp -d /tmp/z_update_test.XXXXXX)
  local target="$fixture/installed copy"
  local upstream="$fixture/source/z-main"
  z.dir.make path="$target/lib"
  z.dir.make path="$target/mod/alpha"
  z.dir.make path="$target/mod/beta"
  z.dir.make path="$upstream/lib"
  z.dir.make path="$upstream/test"
  z.file.write path="$target/main.zsh" content="old main"
  z.file.write path="$target/lib/core.zsh" content="old core"
  z.file.write path="$target/mod/alpha/value" content="old alpha"
  z.file.write path="$target/mod/beta/value" content="old beta"
  z.file.write path="$target/mod/.settings" content="keep settings"
  z.file.write path="$upstream/lib/core.zsh" content="new core"
  z.file.write path="$upstream/main.zsh" content="z_update_test_loaded=true"
  local core_file
  for core_file in install.zsh uninstall.zsh version.zsh help.zsh README.md; do
    z.file.write path="$upstream/$core_file" content=":"
  done
  local mod_name
  for mod_name in alpha beta shared unselected; do
    z.dir.make path="$upstream/mod/$mod_name"
    z.file.write path="$upstream/mod/$mod_name/mod.zsh" content="z.mod $mod_name"
    z.file.write path="$upstream/mod/$mod_name/value" content="new $mod_name"
  done
  z.file.write path="$upstream/mod/alpha/mod.zsh" content=$'z.mod alpha\nz.mod.depends shared\n'
  z.file.write path="$upstream/mod/beta/mod.zsh" content=$'z.mod beta\nz.mod.depends shared\n'
  tar -czf "$fixture/archive.tar.gz" -C "$fixture/source" z-main
  z_update_test_loaded=false
  z.t.mock name="z.update._confirm" behavior="return 0"
  z.t.mock name="z.update._download" behavior="print downloaded >> \"$fixture/downloads\"; z.dir.make path=\"\$1/source\"; tar -xzf \"$fixture/archive.tar.gz\" -C \"\$1/source\"; z.return \"\$1/source/z-main\""
  z.return "$fixture"
}

z.t.describe "z.update"; {
  z.t.context "導入済みmodと共有依存がある場合"; {
    z.t.it "1回の取得で本体とmodを更新し未選択modを追加しない"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      local original_registration=${z_mod_names[completion]}
      z.file.write path="$target/mod/alpha/removed" content=obsolete

      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "new core"
      local mod_name
      for mod_name in alpha beta shared; do
        z.file.read path="$target/mod/$mod_name/value"
        z.t.expect.reply "new $mod_name"
      done
      z.file.read path="$target/mod/.settings"
      z.t.expect.reply "keep settings"
      z.file.exists "$target/mod/alpha/removed"
      z.t.expect.status.is.false
      z.dir.exists "$target/mod/unselected"
      z.t.expect.status.is.false
      z.file.read path="$fixture/downloads"
      z.t.expect.reply downloaded
      z.t.expect "$z_update_test_loaded" true
      z.t.expect "${z_mod_names[completion]}" "$original_registration"
      local -a staging=("$fixture"/.z-update.*(N/))
      z.t.expect "${#staging}" 0
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "modが導入されていない場合"; {
    z.t.it "本体だけを更新する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.dir.remove path="$target/mod"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "new core"
      z.dir.exists "$target/mod"
      z.t.expect.status.is.false
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "インストール先の中から実行した場合"; {
    z.t.it "切り替え後の同じディレクトリへ移動する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      local original_directory=$PWD
      local directory_replaced=false
      () {
        local z_root=$target
        local Z_ROOT=$target
        cd "$target/lib"
        z.update >/dev/null
        local update_result=$?
        [[ . -ef "$target/lib" ]] && directory_replaced=true
        cd "$original_directory"
        return $update_result
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.t.expect "$directory_replaced" true
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "相対パスで読み込んだインストール先の場合"; {
    z.t.it "zのパスAPIで絶対パスへ解決して更新する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      local original_directory=$PWD
      () {
        local z_root="installed copy"
        local Z_ROOT=$z_root
        cd "$fixture"
        z.update >/dev/null 2>&1
        local update_result=$?
        cd "$original_directory"
        return $update_result
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "new core"
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "ダウンロードに失敗した場合"; {
    z.t.it "本体とmodを変更せず一時領域を除去する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.t.mock name="z.update._download" behavior="return 1"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.file.read path="$target/mod/alpha/value"
      z.t.expect.reply "old alpha"
      local -a staging=("$fixture"/.z-update.*(N/))
      z.t.expect "${#staging}" 0
      z.t.expect "$z_update_test_loaded" false
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "更新元に導入済みmodがない場合"; {
    z.t.it "元の本体とmodを残して中断する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.dir.make path="$target/mod/local-only"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null 2>&1
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.file.read path="$target/mod/alpha/value"
      z.t.expect.reply "old alpha"
      z.dir.exists "$target/mod/local-only"
      z.t.expect.status.is.true
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "置換用ファイルの準備に失敗した場合"; {
    z.t.it "元の本体とmodを残す"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.t.mock name="z.update._stage" behavior="return 1"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.file.read path="$target/mod/alpha/value"
      z.t.expect.reply "old alpha"
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "置換用ファイルへの切り替えに失敗した場合"; {
    z.t.it "元のインストール先を復元する"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      local real_mv=$(whence -p mv)
      z.dir.make path="$fixture/bin"
      z.file.write path="$fixture/bin/mv" content="#!/bin/sh
case \"\$1\" in */next) exit 1;; esac
exec \"$real_mv\" \"\$@\"
"
      chmod +x "$fixture/bin/mv"
      () {
        local z_root=$target
        local Z_ROOT=$target
        local PATH="$fixture/bin:$PATH"
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.file.read path="$target/mod/alpha/value"
      z.t.expect.reply "old alpha"
      local -a staging=("$fixture"/.z-update.*(N/))
      z.t.expect "${#staging}" 0
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "切り替えと復元の両方が失敗した場合"; {
    z.t.it "復元用の旧インストールを削除しない"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      local real_mv=$(whence -p mv)
      z.dir.make path="$fixture/bin"
      z.file.write path="$fixture/bin/mv" content="#!/bin/sh
case \"\$1\" in */next|*/previous) exit 1;; esac
exec \"$real_mv\" \"\$@\"
"
      chmod +x "$fixture/bin/mv"
      () {
        local z_root=$target
        local Z_ROOT=$target
        local PATH="$fixture/bin:$PATH"
        z.update >/dev/null 2>&1
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      local -a previous=("$fixture"/.z-update.*/previous(N/))
      z.t.expect "${#previous}" 1
      z.file.read path="$previous[1]/lib/core.zsh"
      z.t.expect.reply "old core"
      z.file.read path="$previous[1]/mod/alpha/value"
      z.t.expect.reply "old alpha"
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "Git管理されたインストール先の場合"; {
    z.t.it "更新処理を開始しない"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.file.write path="$target/.git" content="gitdir: elsewhere"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null 2>&1
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.exists "$fixture/downloads"
      z.t.expect.status.is.false
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "更新の確認をキャンセルした場合"; {
    z.t.it "ダウンロードも変更もしない"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      z.t.mock name="z.update._confirm" behavior="return 1"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 1
      z.file.exists "$fixture/downloads"
      z.t.expect.status.is.false
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "old core"
      z.dir.remove path="$fixture"
    }
  }
  z.t.context "installerの関数が読み込まれていない場合"; {
    z.t.it "zのAPIだけで本体とmodを更新できる"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      () {
        local z_root=$target
        local Z_ROOT=$target
        local function_name
        for function_name in ${(k)functions}; do
          if [[ "$function_name" == z.install || "$function_name" == z.install.* ]]; then
            unfunction "$function_name"
          fi
        done
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "new core"
      z.file.read path="$target/mod/shared/value"
      z.t.expect.reply "new shared"
      z.t.expect "$z_update_test_loaded" true
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "modディレクトリが外部ディレクトリへのリンクの場合"; {
    z.t.it "外部の元データを変更せず置換用ファイルを作る"; {
      z_update_test_fixture
      local fixture=$REPLY
      local target="$fixture/installed copy"
      command mv "$target/mod" "$fixture/external-mods"
      ln -s "$fixture/external-mods" "$target/mod"
      () {
        local z_root=$target
        local Z_ROOT=$target
        z.update >/dev/null
      }
      local update_result=$?

      z.t.expect "$update_result" 0
      z.file.read path="$target/mod/alpha/value"
      z.t.expect.reply "new alpha"
      z.file.read path="$fixture/external-mods/alpha/value"
      z.t.expect.reply "old alpha"
      z.dir.remove path="$fixture"
    }
  }

}
