source ${z_main}

z.t.describe "z.git.fetch"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git fetch --pruneを呼び出す"; {
      z.t.mock name="z.io"
      z.t.mock name="git"

      z.git.fetch

      z.t.mock.result
      z.t.expect.reply "fetch --prune"
    }
  }
}
