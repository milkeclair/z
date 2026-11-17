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

  z.t.context "dumpしたcacheをファイルからsourceする場合"; {
    z.t.it "元のキーと特殊文字を含むdocsを復元し取得できる"; {
      local expected_docs=$(cat <<'DOCS'
show "quoted" docs and 'single quotes'
$name: keep \backslash and `literal`
DOCS
)
      z_completion_docs=()
      z_completion_docs[z.wtproxy]=$expected_docs
      z_completion_function_names=(z.wtproxy)

      z.completion.cache._dump
      local cache_text=$REPLY
      local cache_file=$(mktemp)
      print -r -- "$cache_text" > "$cache_file"

      z_completion_docs=()
      z_completion_function_names=()
      z_completion_cache_ready=false
      source "$cache_file"
      local source_code=$?
      rm -- "$cache_file"

      local restored_keys=${(k)z_completion_docs}
      local restored_docs=${z_completion_docs[z.wtproxy]}
      local restored_names="${z_completion_function_names[@]}"
      local restored_ready=$z_completion_cache_ready

      z.t.expect "$source_code" "0"
      z.t.expect "$restored_keys" "z.wtproxy"
      z.t.expect "$restored_docs" "$expected_docs"
      z.t.expect "$restored_names" "z.wtproxy"
      z.t.expect "$restored_ready" "true"

      z.completion.docs._get z.wtproxy
      local lookup_code=$?
      local lookup_docs=$REPLY

      z.t.expect "$lookup_code" "0"
      z.t.expect "$lookup_docs" "$expected_docs"
    }
  }
}

z.t.describe "z.completion.cache._dump code仕様"; {
  z.t.it "引用した許可値を評価せず保存・復元する"; {
    local fixture_dir=$(mktemp -d)
    local marker=$fixture_dir/never-created
    local cache_file=$fixture_dir/cache.zsh
    local literal="\$(print changed > $marker)"
    local fields=(named behavior code "$literal" "a:b c" "")
    local record="${(j: :)${(@q)fields}}"
    z_completion_argument_specs=()
    z_completion_argument_specs[z.t.mock]=$record

    z.completion.cache._dump
    z.file.write path="$cache_file" content="$REPLY"
    z_completion_argument_specs=()
    source "$cache_file"
    local restored=$z_completion_argument_specs[z.t.mock]
    local example_words=(z.t.mock behavior=print)
    z.completion.argument._select "specs=$restored" current=2 words=example_words
    local choices=("${REPLY[@]}")

    z.t.expect "$restored" "$record"
    z.t.expect "$choices[2]" "$literal"
    z.t.expect "$choices[3]" "a:b c"
    z.t.expect.is.null "$choices[4]"
    z.file.not.exists "$marker"
    z.t.expect.status.is.true
    z.dir.remove path="$fixture_dir"
  }
}
