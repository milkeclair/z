source ${z_main}

z.t.describe "z.completion.compdef._register"; {
  z.t.context "compinit済みの場合"; {
    z.t.it "コマンド位置とz関数の補完を登録する"; {
      local actual=$(z_mode=normal zsh -dfc '
        source "$Z_ROOT/main.zsh"
        autoload -Uz compinit
        compinit -D
        z.completion.cache.build._names
        z.completion.compdef._register || exit 1
        print -r -- "${_comps[-command-]}"
        print -r -- "${_comps[z.arg.named]}"
        print -r -- "${_comps[z.pj]}"
      ')

      z.t.expect "$actual" $'z.completion.complete._command\n_z_completion\nz.pj.completion._run'
    }
  }

  z.t.context "z関数候補のメニューを既に設定している場合"; {
    z.t.it "登録時に利用者の設定を保持する"; {
      local actual=$(z_mode=normal zsh -dfc '
        source "$Z_ROOT/main.zsh"
        autoload -Uz compinit
        compinit -D
        local context=":completion:*:*:*:*:z-functions"
        local -a settings=()
        zstyle "$context" menu no no-select

        z.completion.compdef._register || exit 1
        zstyle -g settings "$context" menu
        print -r -- "$settings"
      ')

      z.t.expect "$actual" "no no-select"
    }
  }

  z.t.context "コマンド補完を繰り返し登録する場合"; {
    z.t.it "既存の補完関数を引数とともに呼べる"; {
      local actual=$(z_mode=normal zsh -dfc '
        source "$Z_ROOT/main.zsh"
        autoload -Uz compinit
        compinit -D
        _fixture_command_completion() { print -r -- "previous: $*"; }
        compdef _fixture_command_completion -command-
        z.completion.cache.build._names
        z.completion.compdef._register || exit 1
        z.completion.compdef._register || exit 1
        source "$Z_ROOT/main.zsh"
        z.completion.cache.build._names
        z.completion.compdef._register || exit 1
        words=(printf)
        CURRENT=1
        z.completion.complete._command original arguments
      ')

      z.t.expect "$actual" "previous: original arguments"
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
