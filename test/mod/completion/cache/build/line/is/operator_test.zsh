source ${z_main}

z.t.describe "z.completion.cache.build.line.is._comment"; {
  z.t.context "comment行の場合"; {
    z.t.it "trueを返す"; {
      z.completion.cache.build.line.is._comment "# docs"

      z.t.expect.status.is.true
    }
  }

  z.t.context "comment行がindentされている場合"; {
    z.t.it "trueを返す"; {
      z.completion.cache.build.line.is._comment "  # docs"

      z.t.expect.status.is.true
    }
  }

  z.t.context "comment行ではない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.build.line.is._comment "z.example.test() {"

      z.t.expect.status.is.false
    }
  }
}
