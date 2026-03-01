source ${z_main}

z.t.describe "z.git.log"; {
  z.t.context "呼び出した場合"; {
    z.t.it "z.git.log.prettyを呼び出す"; {
      z.t.mock name="z.io.empty"
      z.t.mock name="z.io"
      z.t.mock name="z.git.log.pretty" behavior="REPLY=called"

      z.git.log

      z.t.expect.reply "called"
    }
  }
}

z.t.describe "z.git.log.pretty"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git logコマンドを呼び出す"; {
      z.t.mock name="git"

      z.git.log.pretty

      z.t.mock.result
      z.t.expect.reply.includes "log --graph"
    }
  }
}
