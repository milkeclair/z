source ${z_main}

z.t.describe "z.completion.cache._dump"; {
  z.t.context "cacheがある場合"; {
    z.t.it "source可能なcache文字列を返す"; {
      z_completion_docs=()
      z_completion_function_names=()
      z_completion_docs[z.example]="example docs" # zls: ignore
      z_completion_function_names+=(z.example) # zls: ignore

      z.completion.cache._dump
      local cache_text=$REPLY

      z.t.expect.includes "$cache_text" "typeset -gA z_completion_docs=()"
      z.t.expect.includes "$cache_text" 'z_completion_function_names+=("z.example")'
      z.t.expect.includes "$cache_text" "z_completion_cache_ready=true"
    }
  }
}
