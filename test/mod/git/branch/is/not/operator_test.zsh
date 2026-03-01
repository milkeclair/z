source ${z_main}

z.t.describe "z.git.branch.is.not.exists"; {
  z.t.context "ブランチが存在する場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="git" behavior="return 0"

      z.git.branch.is.not.exists main

      z.t.expect.status.is.false
    }
  }

  z.t.context "ブランチが存在しない場合"; {
    z.t.it "trueを返す"; {
      z.t.mock name="git" behavior="return 1"

      z.git.branch.is.not.exists non-existent-branch

      z.t.expect.status.is.true
    }
  }
}
