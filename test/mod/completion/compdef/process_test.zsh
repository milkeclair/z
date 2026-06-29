source ${z_main}

z.t.describe "z.completion.compdef._register"; {
  z.t.context "compdefが利用できる場合"; {
    z.t.it "候補関数を_z_completionへ紐付ける"; {
      local calls_file=/tmp/z_t/completion_compdef_register_calls
      z.dir.make path=${calls_file:h}
      z.file.write path=$calls_file content=""
      z_completion_function_names=(z.example.one z.example.two) # zls: ignore
      z.t.mock name="compdef" behavior="z.file.write.last path=$calls_file content=\"\$1 \$2\""

      z.completion.compdef._register

      z.file.read path=$calls_file
      z.t.expect.reply $'_z_completion z.example.one\n_z_completion z.example.two'
    }
  }
}

z.t.describe "z.completion.compdef._ignore_private"; {
  z.t.context "ignored-patternsが未設定の場合"; {
    z.t.it "private z関数patternを設定する"; {
      local context=':completion:*:*:-command-:*:functions'
      zstyle -d $context ignored-patterns

      z.completion.compdef._ignore_private
      local -a ignored_patterns=()
      zstyle -a $context ignored-patterns ignored_patterns
      z.arr.join.line "${ignored_patterns[@]}"

      z.t.expect.reply 'z.*._*'
      zstyle -d $context ignored-patterns
    }
  }

  z.t.context "ignored-patternsが既にある場合"; {
    z.t.it "既存patternを残してprivate z関数patternを追加する"; {
      local context=':completion:*:*:-command-:*:functions'
      zstyle $context ignored-patterns 'existing-*'

      z.completion.compdef._ignore_private
      local -a ignored_patterns=()
      zstyle -a $context ignored-patterns ignored_patterns
      z.arr.join.line "${ignored_patterns[@]}"

      z.t.expect.reply $'existing-*\nz.*._*'
      zstyle -d $context ignored-patterns
    }
  }

  z.t.context "private z関数patternが既にある場合"; {
    z.t.it "重複追加しない"; {
      local context=':completion:*:*:-command-:*:functions'
      zstyle $context ignored-patterns 'z.*._*'

      z.completion.compdef._ignore_private
      local -a ignored_patterns=()
      zstyle -a $context ignored-patterns ignored_patterns
      z.arr.join.line "${ignored_patterns[@]}"

      z.t.expect.reply 'z.*._*'
      zstyle -d $context ignored-patterns
    }
  }
}
