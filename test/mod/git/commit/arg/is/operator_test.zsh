source ${z_main}

z.t.describe "z.git.commit.arg.is.enough"; {
  z.t.context "引数が足りない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help"
      z.git.commit.arg.is.enough

      z.t.expect.status.is.false
    }

    z.t.it "helpを表示する"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help" behavior="z.return called"

      z.git.commit.arg.is.enough

      z.t.expect.reply "called"
    }
  }

  z.t.context "引数が足りている場合"; {
    z.t.it "trueを返す"; {
      z.git.commit.arg.is.enough -m "commit message"

      z.t.expect.status.is.true
    }
  }
}
