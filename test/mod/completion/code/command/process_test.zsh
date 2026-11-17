source "$z_main"
source "$z_root/test/mod/completion/complete/terminal.zsh"

if ! z92_terminal_start; then
  zpty -d completion_terminal 2>/dev/null
  exit 1
fi
local terminal_fd=$REPLY

{
z.t.describe "z.completion.code.command._complete"; {
  z.t.it "コマンド置換の内側でも通常入力と同じ関数を補完する"; {
    local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture 'print \$(z.fixture.al")

    z.t.expect.includes "$actual" "matches:lines=1:1"
    z.t.expect.includes "$actual" "z.fixture.alpha"
  }

  z.t.it "空白のない区切り直後も新しいコマンド位置にする"; {
    local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture 'true;" 'setup=zstyle ":completion:*" ignored-patterns "^z.fixture.*"')
    z.str.partition "$actual" "matches:lines=" literal=true
    z.str.partition "$REPLY[2]" ":" literal=true
    z.int.is.positive "$REPLY[1]"

    z.t.expect.status.is.true
  }

  z.t.it "内側の引数位置ではその関数のヘルプを表示する"; {
    local setup=$'z_completion_docs[z.fixture.alpha]="INNER_CODE_HELP"\ncompdef _z_completion z.fixture.alpha'
    local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='z.fixture.alpha value " "setup=$setup" display=true wait_for=INNER_CODE_HELP)

    z.t.expect.includes "$actual" "matches:lines=0:"
    z.t.expect.includes "$actual" "INNER_CODE_HELP"
  }
}

z.t.describe "z.completion.code.command._run"; {
  z.t.it "条件分岐の本体を現在のコマンドへ合わせる"; {
    local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture 'if true; then z.fixture.al")

    z.t.expect.includes "$actual" "matches:lines=1:1"
    z.t.expect.includes "$actual" "z.fixture.alpha"
  }
}

z.t.describe "z.completion.code.command._dispatch"; {
  z.t.it "閉じた置換の途中で補完しても括弧とコードを保持する"; {
    local input="z.code_fixture 'print \$(print \$(z.fixture.ala))'"
    local actual=$(z92_terminal "$terminal_fd" "input=$input"$'\002\002\002\002' setup="setopt complete_in_word")
    z.str.partition "$actual" "buffer=" literal=true
    local completed_words=("${(z)REPLY[2]}")
    z.completion.argument._value "$completed_words[-1]"

    z.t.expect.reply 'print $(print $(z.fixture.alpha))'
  }

  z.t.it "二重引用の内側でも閉じ引用符を追加しない"; {
    local input="z.code_fixture 'print \"\$(z.fixture.ala)\"'"
    local actual=$(z92_terminal "$terminal_fd" "input=$input"$'\002\002\002\002' setup="setopt complete_in_word")
    z.str.partition "$actual" "buffer=" literal=true
    local completed_words=("${(z)REPLY[2]}")
    z.completion.argument._value "$completed_words[-1]"

    z.t.expect.reply 'print "$(z.fixture.alpha)"'
  }

  z.t.it "コード内の単引用文字列をコマンド置換として扱わない"; {
    local code="print '\$(z.fixture.al"
    local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture ${(q)code}")

    z.t.expect.includes "$actual" "matches:lines=0:"
    z.t.expect.excludes "$actual" "z.fixture.alpha"
  }

  z.t.it "コード引数と置換の合計の深さを制限する"; {
    local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture 'print \$(z.fixture.al" setup=z_completion_code_depth=31 display=true "wait_for=code argument nesting limit")

    z.t.expect.includes "$actual" "matches:lines=0:"
    z.t.expect.includes "$actual" "code argument nesting limit"
  }
}

} always {
  zpty -d completion_terminal
}
