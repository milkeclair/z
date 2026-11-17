source "$z_main"
source "$z_root/test/mod/completion/complete/terminal.zsh"

local fixture_root="/tmp/z_t/pj_completion_$$"
local -x XDG_CONFIG_HOME="$fixture_root/config"
z.dir.make path="$fixture_root/project with spaces"

if ! z92_terminal_start; then
  zpty -d completion_terminal 2>/dev/null
  z.dir.remove path="$fixture_root"
  exit 1
fi
local terminal_fd=$REPLY

{
z.t.describe "z.pj.completion._run"; {
  z.t.context "登録がない場合"; {
    z.t.it "候補を出さず設定ディレクトリを作らない"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.pj " command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=0:0\nbuffer=z.pj '
      z.dir.not.exists "$XDG_CONFIG_HOME"

      z.t.expect.status.is.true
    }
  }

  z.t.context "複数のプロジェクトが登録済みの場合"; {
    z.t.it "空の引数位置で登録名を1行1件ずつ表示する"; {
      z.pj.add name=alpha dir="$fixture_root/project with spaces" >/dev/null
      z.pj.add name=alpine dir="$fixture_root/project with spaces" >/dev/null
      z.pj.add name=bravo dir="$fixture_root/project with spaces" >/dev/null

      local actual=$(z92_terminal "$terminal_fd" "input=z.pj " command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=3:3\nbuffer=z.pj '
    }

    z.t.it "入力済みの接頭辞に一致する登録名を表示する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.pj alp" command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=2:2\nbuffer=z.pj alp'
    }

    z.t.it "候補が1件なら名前と末尾の空白を挿入する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.pj br" command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=1:1\nbuffer=z.pj bravo '
    }
  }

  z.t.context "接頭辞に一致する登録がない場合"; {
    z.t.it "他のコマンド候補を出さず入力を保持する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.pj missing" command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=0:0\nbuffer=z.pj missing'
    }
  }

  z.t.context "補完開始後に登録を追加・削除した場合"; {
    z.t.it "再有効化せず次のTab操作で最新の名前を使う"; {
      z.pj.add name=later dir="$fixture_root/project with spaces" >/dev/null
      local added=$(z92_terminal "$terminal_fd" "input=z.pj lat" command_path=/usr/bin:/bin)
      z.pj.remove later >/dev/null
      local removed=$(z92_terminal "$terminal_fd" "input=z.pj lat" command_path=/usr/bin:/bin)

      z.t.expect "$added" $'matches:lines=1:1\nbuffer=z.pj later '
      z.t.expect "$removed" $'matches:lines=0:0\nbuffer=z.pj lat'
    }
  }

  z.t.context "登録名が真偽値や関数名に似ている場合"; {
    z.t.it "文字列の名前をそのまま補完する"; {
      z.pj.add name=null dir="$fixture_root/project with spaces" >/dev/null
      z.pj.add name=z.demo dir="$fixture_root/project with spaces" >/dev/null
      local null_name=$(z92_terminal "$terminal_fd" "input=z.pj nul" command_path=/usr/bin:/bin)
      local dotted_name=$(z92_terminal "$terminal_fd" "input=z.pj z.d" command_path=/usr/bin:/bin)

      z.t.expect "$null_name" $'matches:lines=1:1\nbuffer=z.pj null '
      z.t.expect "$dotted_name" $'matches:lines=1:1\nbuffer=z.pj z.demo '
    }
  }

  z.t.context "2つ目の引数を入力している場合"; {
    z.t.it "プロジェクト名を補完しない"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.pj alpha br" command_path=/usr/bin:/bin)

      z.t.expect "$actual" $'matches:lines=0:0\nbuffer=z.pj alpha br'
    }
  }
}
} always {
  zpty -d completion_terminal
  z.dir.remove path="$fixture_root"
}
