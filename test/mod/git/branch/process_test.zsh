source ${z_main}

z.t.describe "z.git.b"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.branchを呼び出す"; {
      z.t.mock name="z.git.branch"

      z.git.b -a

      z.t.mock.result
      z.t.expect.reply "-a"
    }
  }
}

z.t.describe "z.git.b.a"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.branch.allを呼び出す"; {
      z.t.mock name="z.git.branch.all" behavior="z.io called"

      local result=$(z.git.b.a)

      z.t.expect "$result" "called"
    }
  }
}

z.t.describe "z.git.branch"; {
  z.t.context "git branchコマンドを呼び出すとき"; {
    z.t.it "引数を正しく渡す"; {
      z.t.mock name="git"

      z.git.branch -a

      z.t.mock.result
      z.t.expect.reply "branch -a"
    }
  }
}


z.t.describe "z.git.branch.all"; {
  z.t.context "リモートブランチが存在する場合"; {
    z.t.it "ローカルとリモートの両方のブランチを取得する"; {
      local expected="  main\n* current-branch\n  remotes/origin/main\n  remotes/origin/feature-branch"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch -a"; then
          z.return "$expected"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.all

      z.t.expect.reply "$expected"
    }
  }
}
