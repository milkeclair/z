source ${z_main}

z.t.describe "z.reload"; {
  z.t.context "設定ファイルが存在する場合"; {
    z.t.it "現在のシェルへ変数の代入とREPLYを反映する"; {
      local fixture_root="/tmp/z_t/reload_current_$$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"
      local reload_value=before
      z.file.write.literal path="$HOME/.zshrc" content=$'reload_value=loaded\nREPLY=from-config\n'

      z.reload
      local reload_status=$?
      local reload_reply=$REPLY

      z.t.expect "$reload_status" 0
      z.t.expect "$reload_value" loaded
      z.t.expect "$reload_reply" from-config

      z.dir.remove path="$fixture_root"
    }

    z.t.it "呼び出すたびに変更後のファイルを読み直す"; {
      local fixture_root="/tmp/z_t/reload_changed_$$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"
      local reload_value=""
      z.file.write.literal path="$HOME/.zshrc" content='reload_value=first'

      z.reload

      z.t.expect "$reload_value" first
      z.file.write.literal path="$HOME/.zshrc" content='reload_value=second'

      z.reload

      z.t.expect "$reload_value" second

      z.dir.remove path="$fixture_root"
    }

    z.t.it "設定ファイルの標準出力と標準エラーをそのまま渡す"; {
      local fixture_root="/tmp/z_t/reload_output_$$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"
      z.file.write.literal path="$HOME/.zshrc" content=$'print -r -- "reload output"\nprint -r -- "reload error" >&2\n'

      z.reload > "$fixture_root/stdout" 2> "$fixture_root/stderr"

      z.t.expect.status.is.true
      z.file.read path="$fixture_root/stdout"
      z.t.expect.reply "reload output"
      z.file.read path="$fixture_root/stderr"
      z.t.expect.reply "reload error"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "HOMEに空白が含まれる場合"; {
    z.t.it "ホーム内の設定ファイルを読み込む"; {
      local fixture_root="/tmp/z_t/reload home $$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"
      local reload_value=""
      z.file.write.literal path="$HOME/.zshrc" content='reload_value=loaded'

      z.reload

      z.t.expect.status.is.true
      z.t.expect "$reload_value" loaded

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "ZDOTDIRが設定されている場合"; {
    z.t.it "HOME直下の設定ファイルを読み込む"; {
      local fixture_root="/tmp/z_t/reload_zdotdir_$$"
      z.dir.make path="$fixture_root/zdotdir"
      local HOME="$fixture_root"
      local ZDOTDIR="$fixture_root/zdotdir"
      local reload_value=""
      z.file.write.literal path="$HOME/.zshrc" content='reload_value=home'
      z.file.write.literal path="$ZDOTDIR/.zshrc" content='reload_value=zdotdir'

      z.reload

      z.t.expect "$reload_value" home

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "設定ファイルが失敗する場合"; {
    z.t.it "設定ファイルの終了状態を返す"; {
      local fixture_root="/tmp/z_t/reload_failed_$$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"
      z.file.write.literal path="$HOME/.zshrc" content='return 23'

      z.reload

      z.t.expect.status 23

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "設定ファイルが存在しない場合"; {
    z.t.it "sourceの失敗を返す"; {
      local fixture_root="/tmp/z_t/reload_missing_$$"
      z.dir.make path="$fixture_root"
      local HOME="$fixture_root"

      z.reload 2>/dev/null

      z.t.expect.status 127

      z.dir.remove path="$fixture_root"
    }
  }
}
