source ${z_main}

z.t.describe "z.git.stats.author.names"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git logからauthorを取得して返す"; {
      local expected="Alice\nBob\nCharlie"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --format=%an"; then
          z.io "$expected"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.author.names

      z.t.expect.reply.is.arr "Alice" "Bob" "Charlie"
    }
  }

  z.t.context "author名に空白が含まれる場合"; {
    z.t.it "空白をトリムして返す"; {
      local expected="  Alice  \n  Bob\nCharlie  "
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --format=%an"; then
          z.io "$expected"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.author.names

      z.t.expect.reply.is.arr "Alice" "Bob" "Charlie"
    }
  }

  z.t.context "author名にスペースが含まれる場合"; {
    z.t.it "スペースを含むauthor名を正しく扱う"; {
      local expected="Alice\nJohn Doe\nCharlie"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "log --format=%an"; then
          z.io "$expected"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.stats.author.names

      z.t.expect.reply.is.arr "Alice" "Charlie" "John Doe"
    }
  }
}
