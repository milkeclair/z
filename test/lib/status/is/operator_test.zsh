source ${z_main}

z.t.describe "z.status.is.true"; {
  z.t.context "前回のコマンドの終了ステータスがtrueの場合"; {
    z.t.it "trueを返す"; {
      true
      z.status.is.true

      z.t.expect.status.is.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスがfalseの場合"; {
    z.t.it "falseを返す"; {
      false
      z.status.is.true

      z.t.expect.status.is.false
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0の場合"; {
    z.t.it "trueを返す"; {
      (exit 0)
      z.status.is.true

      z.t.expect.status.is.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0以外の場合"; {
    z.t.it "falseを返す"; {
      (exit 1)
      z.status.is.true

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.status.is.false"; {
  z.t.context "前回のコマンドの終了ステータスがfalseの場合"; {
    z.t.it "trueを返す"; {
      false
      z.status.is.false

      z.t.expect.status.is.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスがtrueの場合"; {
    z.t.it "falseを返す"; {
      true
      z.status.is.false

      z.t.expect.status.is.false
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0以外の場合"; {
    z.t.it "trueを返す"; {
      (exit 1)
      z.status.is.false

      z.t.expect.status.is.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0の場合"; {
    z.t.it "falseを返す"; {
      (exit 0)
      z.status.is.false

      z.t.expect.status.is.false
    }
  }
}
