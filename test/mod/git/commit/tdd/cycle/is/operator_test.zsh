source ${z_main}

z.t.describe "z.git.commit.tdd.cycle.is.valid"; {
  z.t.context "有効なコミットサイクルが渡された場合"; {
    z.t.it "trueを返す"; {
      z.git.commit.tdd.cycle.is.valid "red"

      z.t.expect.status.is.true
    }
  }

  z.t.context "無効なコミットサイクルが渡された場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.io.line"
      z.t.mock name="z.git.commit.help"
      z.git.commit.tdd.cycle.is.valid "invalid_cycle"

      z.t.expect.status.is.false
    }
  }
}
