source ${z_main}

z.t.describe "z.completion.cache.load._result"; {
  z.t.context "resultがある場合"; {
    z.t.it "sourceしてcacheを反映する"; {
      local result=/tmp/z_t/completion_cache_load_result
      z.dir.make path=/tmp/z_t
      local lines=(
        "typeset -gA z_completion_docs=()"
        "typeset -ga z_completion_function_names=()"
        "z_completion_function_names+=(z.example)"
        "z_completion_docs[z.example]=doc"
        "z_completion_cache_ready=true"
      )
      z.file.write path=$result content=""
      for line in "${lines[@]}"; do
        z.file.write.last path=$result content="$line"
      done
      z.t.mock name="z.completion.compdef._register" behavior="return 0"

      z.completion.cache.load._result result=$result

      z.t.expect.status.is.true
      z.t.expect "$z_completion_cache_ready" true
      z.t.expect "$z_completion_docs[z.example]" doc
    }
  }

  z.t.context "resultがない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.load._result # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
