source ${z_main}

z.t.describe "z.completion.cache._build"; {
  z.t.context "cache構築後にdoc探索が失敗した場合"; {
    z.t.it "cacheからdocsを返す"; {
      z.completion.cache._build
      z.t.mock name="z.help._find_docs" behavior="return 1"

      z.completion.docs._get z.arg.get # zls: ignore

      z.t.expect.reply.includes "get the argument at the specified index"
    }
  }

  z.t.context "cacheがreadyでdocsがない関数を指定した場合"; {
    z.t.it "docs探索に戻らない"; {
      z_completion_docs=()
      z_completion_cache_ready=true
      z.t.mock name="z.help._find_docs" behavior="return 1"

      z.completion.docs._get z.arg

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }
}
