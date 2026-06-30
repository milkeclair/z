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

z.t.describe "z.completion.cache.build._docs"; {
  z.t.context "呼び出された場合"; {
    z.t.it "cacheを初期化してfileごとの構築へ委譲する"; {
      local original_z_root=$z_root
      local fixture_root=/tmp/z_t/completion_cache_build_docs_root
      local calls_file=/tmp/z_t/completion_cache_build_docs_calls
      z.dir.remove path=$fixture_root
      z.dir.make path=$fixture_root/lib/fixture
      z.dir.make path=$fixture_root/mod/fixture
      z.file.write path=$fixture_root/root.zsh content=""
      z.file.write path=$fixture_root/lib/fixture/process.zsh content=""
      z.file.write path=$fixture_root/mod/fixture/process.zsh content=""
      z.file.write path=$fixture_root/lib/fixture/ignore.txt content=""
      z.dir.make path=${calls_file:h}
      z.file.write path=$calls_file content=""
      z_completion_docs=()
      z_completion_docs[z.stale]="stale" # zls: ignore
      z.t.mock name="z.completion.cache.build.docs._from_file" behavior="z.file.write.last path=$calls_file content=\"\$1\""

      z_root=$fixture_root
      z.completion.cache.build._docs
      local stale_docs=${z_completion_docs[z.stale]} # zls: ignore
      z_root=$original_z_root
      z.file.read path=$calls_file
      local calls=$REPLY
      z.dir.remove path=$fixture_root

      z.t.expect.is.null "$stale_docs"
      z.t.expect.includes "$calls" "$fixture_root/root.zsh"
      z.t.expect.includes "$calls" "$fixture_root/lib/fixture/process.zsh"
      z.t.expect.includes "$calls" "$fixture_root/mod/fixture/process.zsh"
      z.t.expect.excludes "$calls" "$fixture_root/lib/fixture/ignore.txt"
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
