source ${z_main}

z.t.describe "z.mod"; {
  z.t.context "mod nameを指定した場合"; {
    z.t.it "modを登録する"; {
      z.mod.reset

      z.mod git

      z.mod.is.registered git
      z.t.expect.status.is.true
    }
  }

  z.t.context "mod nameを指定しない場合"; {
    z.t.it "失敗する"; {
      z.mod.reset

      z.mod # zls: ignore

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.mod.depends"; {
  z.t.context "dependencyを指定した場合"; {
    z.t.it "current modのdependencyとして保存する"; {
      z.mod.reset

      z.mod wt_proxy; {
        z.mod.depends git
      }

      z.mod.dependencies wt_proxy
      z.t.expect.reply.is.arr git
    }

    z.t.it "重複したdependencyを一度だけ保存する"; {
      z.mod.reset

      z.mod wt_proxy; {
        z.mod.depends git git
      }

      z.mod.dependencies wt_proxy
      z.t.expect.reply.is.arr git
    }
  }

  z.t.context "current modがない場合"; {
    z.t.it "失敗する"; {
      z.mod.reset
      z.t.mock name="z.io.error"

      z.mod.depends git

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "current mod is not set"
    }
  }
}

z.t.describe "z.mod.reset"; {
  z.t.context "modが登録済みの場合"; {
    z.t.it "mod storeを空にする"; {
      z.mod git

      z.mod.reset

      z.mod.is.registered git
      z.t.expect.status.is.false
    }
  }
}
