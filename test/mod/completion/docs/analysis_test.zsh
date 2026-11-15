source ${z_main}

z.t.describe "z.completion.docs._get"; {
  z.t.context "readyなcacheにdocsがある関数を指定した場合"; {
    z.t.it "cache内の正規化されたdocsを返す"; {
      local expected_docs=$'get the argument at the specified index\n\n$index: 1-based index'
      z_completion_docs=()
      z_completion_docs[z.arg.get]=$expected_docs # zls: ignore
      z_completion_cache_ready=true

      z.completion.docs._get z.arg.get # zls: ignore

      z.t.expect.reply "$expected_docs"
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

z.t.describe "z.completion.docs._format"; {
  z.t.context "引数・戻り値・使用例を含む説明の場合"; {
    z.t.it "見出しと引数名と使用例を色分けし字下げを保持する"; {
      local docs=$'plain description\n\n$name?: argument description\n$@: positional arguments\nREPLY: value\nreturn: 0|1\n\nexample:\n  z.example name=value\n    continued\n\nplain footer'
      local expected=$'plain description\n\n%{\e[36m%}$name?:%{\e[0m%} argument description\n%{\e[36m%}$@:%{\e[0m%} positional arguments\n%{\e[33m%}REPLY:%{\e[0m%} value\n%{\e[33m%}return:%{\e[0m%} 0|1\n\n%{\e[33m%}example:%{\e[0m%}\n%{\e[32m%}  z.example name=value%{\e[0m%}\n%{\e[32m%}    continued%{\e[0m%}\n\nplain footer'

      z.completion.docs._format "$docs"

      z.t.expect.reply "$expected"
    }
  }

  z.t.context "説明にZshのprompt記号が含まれる場合"; {
    z.t.it "本文と使用例のpercentを文字として表示できるようにする"; {
      z.completion.docs._format $'100% %F{red}literal%f\nexample:\n  printf "%s" value'

      z.t.expect.reply $'100%% %%F{red}literal%%f\n%{\e[33m%}example:%{\e[0m%}\n%{\e[32m%}  printf "%%s" value%{\e[0m%}'
    }
  }

  z.t.context "使用例ではない字下げ行がある場合"; {
    z.t.it "通常色と空行を保持する"; {
      z.completion.docs._format $'plain\n  detail\n\nmore'

      z.t.expect.reply $'plain\n  detail\n\nmore'
    }
  }

  z.t.context "説明が空の場合"; {
    z.t.it "空文字を返す"; {
      z.completion.docs._format ""

      z.t.expect.reply ""
    }
  }
}
