source ${z_main}

z.t.describe "z.git.push"; {
  z.t.context "引数にoriginが含まれる場合"; {
    z.t.it "git pushを引数付きで実行する"; {
      z.t.mock name="z.git._hp.arg.has.origin" behavior="return 0"
      z.t.mock name="git"

      z.git.push origin main

      z.t.mock.result
      z.t.expect.reply "push origin main"
    }
  }

  z.t.context "z.git.push._prが成功した場合"; {
    z.t.it "z.git.push._currentを呼ばない"; {
      z.t.mock name="z.git._hp.arg.has.origin" behavior="return 1"
      z.t.mock name="z.git.push._pr" behavior="z.return called"
      z.t.mock name="z.git.push._current" behavior="z.return current"

      z.git.push

      z.t.expect.reply "called"
    }
  }

  z.t.context "z.git.push._prが失敗した場合"; {
    z.t.it "z.git.push._currentを呼ぶ"; {
      z.t.mock name="z.git._hp.arg.has.origin" behavior="return 1"
      z.t.mock name="z.git.push._pr" behavior="return 1"
      z.t.mock name="z.git.push._current" behavior="z.return called"

      z.git.push

      z.t.expect.reply "called"
    }
  }
}

z.t.describe "z.git.push._pr"; {
  z.t.context "現在のブランチにpr番号が含まれる場合"; {
    z.t.it "PR向けのpushを実行する"; {
      z.t.mock name="z.git.branch.current._get" behavior='REPLY="pr/123"'
      z.t.mock name="z.io"
      z.t.mock name="z.io.empty"
      z.t.mock name="gh" behavior='echo feature/register'
      z.t.mock name="git"

      z.git.push._pr

      z.t.mock.result name="git"
      z.t.expect.reply "push --set-upstream origin HEAD:feature/register"
    }
  }

  z.t.context "現在のブランチにpr番号が含まれない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.git.branch.current._get" behavior="z.return main"
      z.t.mock name="git"

      z.git.push._pr

      z.t.expect.status.is.false
      z.t.mock.result name="git"
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.git.push._current"; {
  z.t.context "呼び出した場合"; {
    z.t.it "現在のブランチをupstream付きでpushする"; {
      z.t.mock name="z.git.branch.current._get" behavior="z.return main"
      z.t.mock name="z.io"
      z.t.mock name="z.io.empty"
      z.t.mock name="git"

      z.git.push._current

      z.t.mock.result name="git"
      z.t.expect.reply "push --set-upstream origin main"
    }
  }
}
