source ${z_main}

z.t.describe "z.completion.docs._get"; {
  z.t.context "readyなcacheにdocsがある関数を指定した場合"; {
    z.t.it "cache内の正規化されたdocsを返す"; {
      z_completion_docs=()
      z_completion_docs[z.arg.get]=$'get the argument at the specified index\n\n$index: 1-based index' # zls: ignore
      z_completion_cache_ready=true

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

      REPLY=stale
      z.completion.docs._get z.missing # zls: ignore
      local lookup_code=$?
      local docs=$REPLY

      z.t.expect "$lookup_code" "1" skip_unmock=true
      z.t.expect "$docs" "" skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }

  z.t.context "cacheが未readyでdocsがない場合"; {
    z.t.it "同期doc探索を呼ばず空のREPLYとfalseを返す"; {
      z_completion_docs=()
      z_completion_cache_ready=false
      z.t.mock name="z.help._find_docs" behavior="z.return fallback"

      REPLY=stale
      z.completion.docs._get z.missing # zls: ignore
      local lookup_code=$?
      local docs=$REPLY

      z.t.expect "$lookup_code" "1" skip_unmock=true
      z.t.expect "$docs" "" skip_unmock=true
      z.t.mock.result name="z.help._find_docs"
      z.t.expect.reply ""
    }
  }
}
