source ${z_main}

z.t.describe "z.status.is_true"; {
  z.t.context "前回のコマンドの終了ステータスがtrueの場合"; {
    z.t.it "trueを返す"; {
      true
      z.status.is_true

      z.t.expect.status.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスがfalseの場合"; {
    z.t.it "falseを返す"; {
      false
      z.status.is_true

      z.t.expect.status.false
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0の場合"; {
    z.t.it "trueを返す"; {
      (exit 0)
      z.status.is_true

      z.t.expect.status.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0以外の場合"; {
    z.t.it "falseを返す"; {
      (exit 1)
      z.status.is_true

      z.t.expect.status.false
    }
  }
}

z.t.describe "z.status.is_false"; {
  z.t.context "前回のコマンドの終了ステータスがfalseの場合"; {
    z.t.it "trueを返す"; {
      false
      z.status.is_false

      z.t.expect.status.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスがtrueの場合"; {
    z.t.it "falseを返す"; {
      true
      z.status.is_false

      z.t.expect.status.false
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0以外の場合"; {
    z.t.it "trueを返す"; {
      (exit 1)
      z.status.is_false

      z.t.expect.status.true
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0の場合"; {
    z.t.it "falseを返す"; {
      (exit 0)
      z.status.is_false

      z.t.expect.status.false
    }
  }
}
