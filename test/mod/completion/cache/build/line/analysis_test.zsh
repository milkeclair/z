source ${z_main}

z.t.describe "z.completion.cache.build.line._function_name"; {
  z.t.context "z関数宣言行の場合"; {
    z.t.it "関数名を返す"; {
      z.completion.cache.build.line._function_name "z.example.test() {"

      z.t.expect.reply "z.example.test"
    }
  }

  z.t.context "z関数宣言行がindentされている場合"; {
    z.t.it "関数名を返す"; {
      z.completion.cache.build.line._function_name "  z.example.test() {"

      z.t.expect.reply "z.example.test"
    }
  }

  z.t.context "z関数ではない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.build.line._function_name "example.test() {"

      z.t.expect.status.is.false
    }
  }

  z.t.context "宣言suffixがbraceではない場合"; {
    z.t.it "falseを返す"; {
      z.completion.cache.build.line._function_name "z.example.test() echo"

      z.t.expect.status.is.false
    }
  }
}
