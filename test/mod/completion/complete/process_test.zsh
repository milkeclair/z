source ${z_main}

z.t.describe "z.completion.complete._command"; {
  z.t.context "コマンド位置でz関数を補完する場合"; {
    z.t.it "実際の候補を1行1件で表示する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z.fixture.)

      z.t.expect "$actual" $'matches:lines=2:2\nbuffer=z.fixture.'
    }
  }

  z.t.context "z.からnamespaceを選ぶ場合"; {
    z.t.it "namespaceを1件にまとめて空白を付けず挿入する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z. 'setup=zstyle ":completion:*:z-functions" ignored-patterns "^z.fixture.*"')

      z.t.expect "$actual" $'matches:lines=1:1\nbuffer=z.fixture.'
    }
  }

  z.t.context "同じ接頭辞のaliasがある場合"; {
    z.t.it "aliasも補完候補として維持する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z.fixture. "setup=alias z.fixture.alias=:")

      z.t.expect.includes "$actual" "matches:lines=3:"
    }
  }

  z.t.context "同じ接頭辞の外部コマンドがある場合"; {
    z.t.it "外部コマンドも補完候補として維持する"; {
      local fixture_dir=$(mktemp -d)
      z.file.write path=$fixture_dir/z.fixture.external content=$'#!/bin/sh\nexit 0'
      z.perm path=$fixture_dir/z.fixture.external mode=755
      local actual=$(PATH="$fixture_dir:$PATH" zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z.fixture.)
      z.dir.remove path=$fixture_dir

      z.t.expect.includes "$actual" "matches:lines=3:"
    }
  }

  z.t.context "commandに続く名前を補完する場合"; {
    z.t.it "シェル関数を外部コマンドの候補に含めない"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" "input=command z.fixture.")

      z.t.expect "$actual" $'matches:lines=0:0\nbuffer=command z.fixture.'
    }
  }

  z.t.context "候補が1件の場合"; {
    z.t.it "候補名を入力へ挿入する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z.fixture.al)

      z.t.expect "$actual" $'matches:lines=1:1\nbuffer=z.fixture.alpha '
    }
  }

  z.t.context "一般のコマンド名を補完する場合"; {
    z.t.it "従来の補完で候補を入力へ挿入する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=fixture-c "setup=alias fixture-command=:")

      z.t.expect "$actual" $'matches:lines=1:1\nbuffer=fixture-command '
    }
  }

  z.t.context "main.zshを読み直した場合"; {
    z.t.it "登録済みの補完を維持して候補を表示できる"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" input=z.fixture. 'setup=source "$Z_ROOT/main.zsh"; z.completion.cache.build._names; z.completion.compdef._register')

      z.t.expect "$actual" $'matches:lines=2:2\nbuffer=z.fixture.'
    }
  }
}

z.t.describe "z.completion.complete._run"; {
  z.t.context "関数名補完が成功した場合"; {
    z.t.it "docs表示を実行しない"; {
      z.t.mock name="z.completion.complete._functions" behavior="z.return functions"
      z.t.mock name="z.completion.complete._docs" behavior="z.return docs"

      z.completion.complete._run

      z.t.expect.reply functions
    }
  }

  z.t.context "関数名補完が失敗した場合"; {
    z.t.it "docs表示へfallbackする"; {
      z.t.mock name="z.completion.complete._functions" behavior="return 1"
      z.t.mock name="z.completion.complete._docs" behavior="z.return docs"

      z.completion.complete._run

      z.t.expect.reply docs
    }
  }
}

z.t.describe "z.completion.complete._functions"; {
  z.t.context "current wordがz関数prefixの場合"; {
    z.t.it "引数位置でも実際の候補を1行1件で表示する"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" "input=z.arg.named z.fixture.")

      z.t.expect "$actual" $'matches:lines=2:2\nbuffer=z.arg.named z.fixture.'
    }
  }

  z.t.context "引数位置でz.からnamespaceを選ぶ場合"; {
    z.t.it "namespaceの直後から続けて入力できる"; {
      local actual=$(zsh "$z_root/test/mod/completion/complete/terminal.zsh" "input=z.arg.named z." 'setup=zstyle ":completion:*:z-functions" ignored-patterns "^z.fixture.*"')

      z.t.expect "$actual" $'matches:lines=1:1\nbuffer=z.arg.named z.fixture.'
    }
  }

  z.t.context "current wordがz関数prefixではない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="_describe" behavior="z.return called"
      words=(example)
      CURRENT=1

      z.completion.complete._functions

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="_describe"
      z.t.expect.reply ""
    }
  }

  z.t.context "current wordがz関数prefixだが候補がない場合"; {
    z.t.it "_describeを呼ばずfalseを返す"; {
      z.t.mock name="z.completion.function._candidates" behavior="return 1"
      z.t.mock name="_describe" behavior="z.return called"
      words=(z.unknown) # zls: ignore
      CURRENT=1

      z.completion.complete._functions

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="_describe"
      z.t.expect.reply ""
    }
  }
}

z.t.describe "z.completion.complete._docs"; {
  z.t.context "関数の引数位置でTabを押した場合"; {
    z.t.it "関数docsを表示する"; {
      z_completion_docs=()
      z_completion_docs[z.arg.named]=$'get named argument value\n\n$name: name of the argument'
      z_completion_cache_ready=true
      z.t.mock name="_message" behavior='z.return "$2"'
      words=(z.arg.named "")
      CURRENT=2

      z.completion.complete._docs
      local output=$REPLY

      z.t.expect.includes "$output" "get named argument value"
      z.t.expect.excludes "$output" $'z.arg.named\nget named argument value'
      z.t.expect.includes "$output" "name of the argument"
    }
  }

  z.t.context "wordsから関数名を取得できない場合"; {
    z.t.it "_messageを呼ばずfalseを返す"; {
      z.t.mock name="_message" behavior='z.return "$*"'
      words=(example "")
      CURRENT=2

      z.completion.complete._docs

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="_message"
      z.t.expect.reply ""
    }
  }

  z.t.context "関数名はあるがdocsがない場合"; {
    z.t.it "_messageを呼ばずfalseを返す"; {
      z_completion_docs=()
      z_completion_cache_ready=true
      z.t.mock name="_message" behavior='z.return "$*"'
      words=(z.arg.named "")
      CURRENT=2

      z.completion.complete._docs

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="_message"
      z.t.expect.reply ""
    }
  }
}
