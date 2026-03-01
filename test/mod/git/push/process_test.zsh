source ${z_main}

z.t.describe "z.git.push"; {
  z.t.context "引数にoriginが含まれる場合"; {
    z.t.it "git pushを引数付きで実行する"; {
      z.t.mock name="z.git.hp.arg.has.origin" behavior="return 0"
      z.t.mock name="git"

      z.git.push origin main

      z.t.mock.result
      z.t.expect.reply "push origin main"
    }
  }

  z.t.context "z.git.push.prが成功した場合"; {
    z.t.it "z.git.push.currentを呼ばない"; {
      z.t.mock name="z.git.hp.arg.has.origin" behavior="return 1"
      z.t.mock name="z.git.push.pr" behavior="z.return called"
      z.t.mock name="z.git.push.current" behavior="z.return current"

      z.git.push

      z.t.expect.reply "called"
    }
  }

  z.t.context "z.git.push.prが失敗した場合"; {
    z.t.it "z.git.push.currentを呼ぶ"; {
      z.t.mock name="z.git.hp.arg.has.origin" behavior="return 1"
      z.t.mock name="z.git.push.pr" behavior="return 1"
      z.t.mock name="z.git.push.current" behavior="z.return called"

      z.git.push

      z.t.expect.reply "called"
    }
  }
}

z.t.describe "z.git.push.pr"; {
  z.t.context "現在のブランチにpr番号が含まれる場合"; {
    z.t.it "PR向けのpushを実行する"; {
      z.t.mock name="z.git.branch.current.get" behavior='REPLY="pr/123"'
      z.t.mock name="z.io"
      z.t.mock name="z.io.empty"
      z.t.mock name="git"

      z.git.push.pr

      z.t.mock.result name="git"
      z.t.expect.reply "push origin HEAD:refs/pull/123/head"
    }
  }

  z.t.context "現在のブランチにpr番号が含まれない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return main"
      z.t.mock name="git"

      z.git.push.pr

      z.t.expect.status.is.false
      z.t.mock.result name="git"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.git.push.current"; {
  z.t.context "呼び出した場合"; {
    z.t.it "現在のブランチをupstream付きでpushする"; {
      z.t.mock name="z.git.branch.current.get" behavior="z.return main"
      z.t.mock name="z.io"
      z.t.mock name="z.io.empty"
      z.t.mock name="git"

      z.git.push.current

      z.t.mock.result name="git"
      z.t.expect.reply "push --set-upstream origin main"
    }
  }
}
