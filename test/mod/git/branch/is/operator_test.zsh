source ${z_main}

z.t.describe "z.git.branch.is.exists"; {
  z.t.context "ブランチが存在する場合"; {
    z.t.it "trueを返す"; {
      z.t.mock name="git" behavior="return 0"

      z.git.branch.is.exists main

      z.t.expect.status.is.true
    }
  }

  z.t.context "ブランチが存在しない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="git" behavior="return 1"

      z.git.branch.is.exists non-existent-branch

      z.t.expect.status.is.false
    }
  }

  z.t.context "gitコマンドを呼び出すとき"; {
    z.t.it "引数を正しく渡す"; {
      z.t.mock name="git"

      z.git.branch.is.exists feature-branch

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result
      z.t.expect.reply "show-ref --verify --quiet refs/heads/feature-branch"
    }
  }
}
