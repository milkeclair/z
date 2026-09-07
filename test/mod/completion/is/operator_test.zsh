source ${z_main}

z.t.describe "z.completion.is._interactive"; {
  z.t.context "-cを指定しない対話シェルの場合"; {
    z.t.it "trueを返す"; {
      zsh -fis 2>/dev/null <<'ZSH'
source "$Z_ROOT/mod/completion/is/operator.zsh" || exit 2
z.completion.is._interactive
exit $?
ZSH

      z.t.expect.status.is.true
    }
  }

  z.t.context "-icでコマンドを実行する場合"; {
    z.t.it "falseを返す"; {
      zsh -fic 'source "$Z_ROOT/mod/completion/is/operator.zsh" || exit 2; z.completion.is._interactive' 2>/dev/null

      z.t.expect.status 1
    }
  }

  z.t.context "-cでコマンドを実行する場合"; {
    z.t.it "falseを返す"; {
      zsh -fc 'source "$Z_ROOT/mod/completion/is/operator.zsh" || exit 2; z.completion.is._interactive'

      z.t.expect.status 1
    }
  }

  z.t.context "標準入力を読む非対話シェルの場合"; {
    z.t.it "falseを返す"; {
      zsh -fs <<'ZSH'
source "$Z_ROOT/mod/completion/is/operator.zsh" || exit 2
z.completion.is._interactive
exit $?
ZSH

      z.t.expect.status 1
    }
  }

  z.t.context "-icに空のコマンド文字列を渡す場合"; {
    z.t.it "起動時にもfalseを返す"; {
      local completion_zdotdir=$(mktemp -d)
      cat > "$completion_zdotdir/.zshenv" <<'ZSH'
source "$Z_ROOT/mod/completion/is/operator.zsh" || exit 2
z.completion.is._interactive
print -r -- $?
unsetopt rcs
ZSH
      local actual=$(ZDOTDIR="$completion_zdotdir" zsh -ic '' 2>/dev/null)
      rm -- "$completion_zdotdir/.zshenv"
      rmdir -- "$completion_zdotdir"

      z.t.expect "$actual" "1"
    }
  }
}
