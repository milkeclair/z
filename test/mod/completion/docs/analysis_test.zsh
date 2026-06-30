source ${z_main}

z.t.describe "z.completion.docs._get"; {
  z.t.context "docsを持つ関数を指定した場合"; {
    z.t.it "正規化されたdocsを返す"; {
      z.completion.docs._get z.arg.get # zls: ignore
      local docs=$REPLY

      z.t.expect.includes "$docs" "get the argument at the specified index"
      z.t.expect.includes "$docs" "index: 1-based index"
    }
  }

  z.t.context "cacheにdocsがある場合"; {
    z.t.it "doc探索に戻らずcacheから返す"; {
      z_completion_docs=()
      z_completion_docs[z.example]="cached docs" # zls: ignore
      z_completion_cache_ready=false
      z.t.mock name="z.help._find_docs" behavior="z.return fallback"

      z.completion.docs._get z.example # zls: ignore

      z.t.expect.reply "cached docs" skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }

  z.t.context "cacheがreadyでdocsがない関数を指定した場合"; {
    z.t.it "doc探索に戻らずfalseを返す"; {
      z_completion_docs=()
      z_completion_cache_ready=true
      z.t.mock name="z.help._find_docs" behavior="z.return fallback"

      z.completion.docs._get z.missing # zls: ignore

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }

  z.t.context "cacheが未readyでdoc探索が失敗した場合"; {
    z.t.it "falseを返す"; {
      z_completion_docs=()
      z_completion_cache_ready=false
      z.t.mock name="z.help._find_docs" behavior="return 1"

      z.completion.docs._get z.missing # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
