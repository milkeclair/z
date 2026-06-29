source ${z_main}

z.t.describe "z.completion.function.is._private"; {
  z.t.context "private関数名を指定した場合"; {
    z.t.it "trueを返す"; {
      z.completion.function.is._private z.wtproxy._state.init

      z.t.expect.status.is.true
    }
  }

  z.t.context "public関数名を指定した場合"; {
    z.t.it "falseを返す"; {
      z.completion.function.is._private z.wtproxy.start

      z.t.expect.status.is.false
    }
  }
}
