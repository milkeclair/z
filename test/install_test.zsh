source "$z_main"

z.t.describe "z.install"; {
  z.t.context "インストール済みmodがある更新"; {
    z.t.it "本体を置き換えてmodの内容を維持する"; {
      local fixture=$(mktemp -d /tmp/z_install_preserve.XXXXXX)
      local target="$fixture/installed z"
      local archive="$fixture/archive"
      z.dir.make path="$target/mod/completion/nested"
      z.dir.make path="$target/lib"
      z.dir.make path="$archive/lib"
      z.dir.make path="$archive/test"
      z.dir.make path="$archive/mod/unselected"
      z.file.write path="$target/lib/obsolete.zsh" content=obsolete
      z.file.write path="$target/mod/completion/nested/custom.zsh" content="installed mod"
      z.file.write path="$target/mod/completion/.settings" content="keep settings"
      z.file.write path="$archive/lib/core.zsh" content="updated core"
      z.file.write path="$archive/main.zsh" content="updated main"
      z.file.write path="$archive/mod/unselected/mod.zsh" content="not selected"

      z.t.mock name="z.install._question_overwrite_install_dir" behavior="return 0"
      z.t.mock name="z.install._create_temp_dir" behavior="temp_dir=\"$fixture/download\"; mkdir -p \"\$temp_dir\""
      z.t.mock name="z.install._download_archive" behavior="return 0"
      z.t.mock name="z.install._decompress_archive" behavior="source_dir=\"$archive\""
      z.t.mock name="z.install._zshrc_exists" behavior="return 1"

      z.install "$target" >/dev/null
      local install_result=$?

      z.t.expect "$install_result" 0
      z.file.read path="$target/mod/completion/nested/custom.zsh"
      z.t.expect.reply "installed mod"
      z.file.read path="$target/mod/completion/.settings"
      z.t.expect.reply "keep settings"
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "updated core"
      z.file.read path="$target/main.zsh"
      z.t.expect.reply "updated main"
      z.file.exists "$target/lib/obsolete.zsh"
      z.t.expect.status.is.false
      z.dir.exists "$target/mod/unselected"
      z.t.expect.status.is.false
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "modがない新規インストール"; {
    z.t.it "未選択のmodを導入せず本体だけを配置する"; {
      local fixture=$(mktemp -d /tmp/z_install_new.XXXXXX)
      local target="$fixture/installed"
      local archive="$fixture/archive"
      z.dir.make path="$archive/lib"
      z.dir.make path="$archive/test"
      z.dir.make path="$archive/mod/unselected"
      z.file.write path="$archive/lib/core.zsh" content="new core"
      z.file.write path="$archive/main.zsh" content="new main"
      z.file.write path="$archive/mod/unselected/mod.zsh" content="not selected"

      z.t.mock name="z.install._question_overwrite_install_dir" behavior="return 0"
      z.t.mock name="z.install._create_temp_dir" behavior="temp_dir=\"$fixture/download\"; mkdir -p \"\$temp_dir\""
      z.t.mock name="z.install._download_archive" behavior="return 0"
      z.t.mock name="z.install._decompress_archive" behavior="source_dir=\"$archive\""
      z.t.mock name="z.install._zshrc_exists" behavior="return 1"

      z.install "$target" >/dev/null
      local install_result=$?

      z.t.expect "$install_result" 0
      z.file.read path="$target/lib/core.zsh"
      z.t.expect.reply "new core"
      z.dir.exists "$target/mod"
      z.t.expect.status.is.false
      z.dir.remove path="$fixture"
    }
  }

  z.t.context "modの退避に失敗する更新"; {
    z.t.it "既存の本体とmodを削除せず中断する"; {
      local fixture=$(mktemp -d /tmp/z_install_backup_failure.XXXXXX)
      local target="$fixture/installed"
      local archive="$fixture/archive"
      z.dir.make path="$target/mod/completion"
      z.dir.make path="$archive/lib"
      z.dir.make path="$archive/test"
      z.file.write path="$target/main.zsh" content="original main"
      z.file.write path="$target/mod/completion/custom.zsh" content="original mod"
      z.file.write path="$archive/main.zsh" content="updated main"

      z.t.mock name="z.install._question_overwrite_install_dir" behavior="return 0"
      z.t.mock name="z.install._create_temp_dir" behavior="temp_dir=\"$fixture/download\"; mkdir -p \"\$temp_dir\""
      z.t.mock name="z.install._download_archive" behavior="return 0"
      z.t.mock name="z.install._decompress_archive" behavior="source_dir=\"$archive\""
      z.t.mock name="z.install._zshrc_exists" behavior="return 1"
      z.t.mock name="cp" behavior="return 1"

      z.install "$target" >/dev/null
      local install_result=$?

      z.t.expect "$install_result" 1
      z.file.read path="$target/main.zsh"
      z.t.expect.reply "original main"
      z.file.read path="$target/mod/completion/custom.zsh"
      z.t.expect.reply "original mod"
      z.dir.remove path="$fixture"
    }
  }
}
