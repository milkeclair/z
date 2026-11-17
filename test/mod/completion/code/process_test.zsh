source "$z_main"
source "$z_root/test/mod/completion/complete/terminal.zsh"

if ! z92_terminal_start; then
  zpty -d completion_terminal 2>/dev/null
  exit 1
fi
local terminal_fd=$REPLY

{
z.t.describe "z.completion.code._complete"; {
  z.t.context "現在の引数がcode型の場合"; {
    z.t.it "名前付きcode引数で内側の関数を補完する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='z.fixture.al")

      z.t.expect.includes "$actual" "matches:lines=1:1"
      z.t.expect.includes "$actual" "z.fixture.alpha"
      z.t.expect.includes "$actual" "behavior="
    }

    z.t.it "位置引数のcode型を補完する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture 'z.fixture.al")

      z.t.expect.includes "$actual" "matches:lines=1:1"
      z.t.expect.includes "$actual" "z.fixture.alpha"
    }
  }

  z.t.context "コード引数が入れ子の場合"; {
    z.t.it "コード引数の入れ子でも補完する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=outer behavior='z.t.mock name=inner behavior=\"z.fixture.al")

      z.t.expect.includes "$actual" "z.fixture.alpha"
    }
  }

  z.t.context "カーソルがコード内のコメントにある場合"; {
    z.t.it "コードのコメント内では関数候補を増やさない"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='print ok # z.fixture.al")

      z.t.expect.includes "$actual" "matches:lines=0:"
      z.t.expect.excludes "$actual" "buffer=z.t.mock name=example behavior=z.fixture.alpha"
    }
  }

  z.t.context "コードに副作用のあるコマンドが含まれる場合"; {
    z.t.it "補完のために文字列のコマンドを実行しない"; {
      local fixture_dir=$(mktemp -d)
      local marker=$fixture_dir/never-created
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='print changed > $marker; z.fixture.al")

      z.t.expect.includes "$actual" "z.fixture.alpha"
      z.file.not.exists "$marker"
      z.t.expect.status.is.true
      z.dir.remove path="$fixture_dir"
    }
  }

  z.t.context "カーソルが閉じた引用の途中にある場合"; {
    z.t.it "閉じた引用符とカーソル後ろのコードを保って補完する"; {
      local input="z.t.mock name=example behavior='z.fixture.ala; print ok'"
      # 閉じ引用符から12文字戻り、alとaの間で補完する
      local backwards=$'\002\002\002\002\002\002\002\002\002\002\002\002'
      local actual=$(z92_terminal "$terminal_fd" "input=$input$backwards" setup="setopt complete_in_word")

      z.t.expect.includes "$actual" "matches:lines=1:1"
      z.t.expect.includes "$actual" "z.fixture.alpha"
      z.str.partition "$actual" "buffer="
      local completed_words=(${(z)REPLY[2]})
      z.completion.argument._value "$completed_words[-1]"
      z.t.expect.reply "behavior=z.fixture.alpha; print ok"
    }
  }

  z.t.context "入れ子の上限を越える場合"; {
    z.t.it "入れ子の上限を越えると補完処理を止める"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='z.fixture.al" setup=z_completion_code_depth=32 display=true "wait_for=code argument nesting limit")

      z.t.expect.includes "$actual" "matches:lines=0:"
      z.t.expect.includes "$actual" "code argument nesting limit"
    }
  }

  z.t.context "code型でない引数の場合"; {
    z.t.it "code型でない名前付き引数を内側のコマンドにしない"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name='z.fixture.al")

      z.t.expect.includes "$actual" "matches:lines=0:"
      z.t.expect.excludes "$actual" "buffer=z.t.mock name=z.fixture.alpha"
    }
  }

  z.t.context "許可値が空文字の場合"; {
    z.t.it "空の許可値とdefault=のような許可値を区別する"; {
      local setup="z_completion_argument_specs[z.code_fixture]=\"positional 1 code '' default=x\""
      local actual=$(z92_terminal "$terminal_fd" "input=z.code_fixture ''" "setup=$setup")

      z.t.expect.includes "$actual" "matches:lines=0:"
    }
  }
}

z.t.describe "z.completion.code._dispatch"; {
  z.t.context "コード文字列を補完する場合"; {
    z.t.it "二重引用とANSI引用でも候補を返す"; {
      local double=$(z92_terminal "$terminal_fd" 'input=z.t.mock name=example behavior="z.fixture.al')
      local ansi=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior=\$'z.fixture.al")

      z.t.expect.includes "$double" "matches:lines=1:1"
      z.t.expect.includes "$ansi" "matches:lines=1:1"
    }

    z.t.it "セミコロン後のコマンド位置を補完する"; {
      local actual=$(z92_terminal "$terminal_fd" "input=z.t.mock name=example behavior='print ok; z.fixture.al")

      z.t.expect.includes "$actual" "matches:lines=1:1"
      z.t.expect.includes "$actual" "z.fixture.alpha"
    }
  }

  z.t.context "許可値を補完する場合"; {
    z.t.it "許可値も候補として補完する"; {
      local actual=$(z92_terminal "$terminal_fd" input=z.t.mock\ name=example\ behavior=call_ori)

      z.t.expect.includes "$actual" "call_original"
    }
  }
}

} always {
  zpty -d completion_terminal
}
