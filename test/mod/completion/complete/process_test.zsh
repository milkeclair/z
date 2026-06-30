source ${z_main}

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
    z.t.it "candidateを_describeへ渡す"; {
      z.t.mock name="z.completion.function._candidates" behavior="z.return $'z.example.one\nz.example.two'"
      z.t.mock name="_describe" behavior='z.return "$*"'
      words=(z.example) # zls: ignore
      CURRENT=1

      z.completion.complete._functions

      z.t.expect.reply "-t z-functions z functions candidates"
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
