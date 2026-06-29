source ${z_main}

z.t.describe "z.completion.cache.build._names"; {
  z.t.context "呼び出された場合"; {
    z.t.it "publicだけをcacheする"; {
      z_completion_function_names=(stale.function)

      z.completion.cache.build._names

      z.arr.includes target=z.completion.enable "${z_completion_function_names[@]}"
      z.t.expect.status.is.true
      z.arr.includes target=z.completion.cache._build "${z_completion_function_names[@]}"
      z.t.expect.status.is.false
      z.arr.includes target=stale.function "${z_completion_function_names[@]}"
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.completion.cache.build._result"; {
  z.t.context "resultを指定した場合"; {
    z.t.it "source可能なcacheをresult fileへ書き込む"; {
      local result_dir=/tmp/z_t/completion_cache_result_dir
      local result=$result_dir/result
      z.dir.remove path=$result_dir
      z.dir.make path=/tmp/z_t
      z.dir.make path=$result_dir
      z.t.mock name="z.completion.cache._build" behavior=$'
        z_completion_docs=()
        z_completion_function_names=()
        z_completion_docs[z.example]="example docs" # zls: ignore
        z_completion_function_names+=(z.example) # zls: ignore
        z_completion_cache_ready=true
      '

      z.completion.cache.build._result result=$result

      z.file.read path=$result
      local cache_content=$REPLY
      z.t.expect.includes "$cache_content" "typeset -gA z_completion_docs=()"
      z.t.expect.includes "$cache_content" 'z_completion_docs["z.example"]="example docs"'
      z.t.expect.includes "$cache_content" "z_completion_cache_ready=true"
    }
  }

  z.t.context "resultがない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.build._result # zls: ignore

      z.t.expect.status.is.false
    }
  }
}
