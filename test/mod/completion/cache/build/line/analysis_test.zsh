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

  z.t.context "先頭空白を除去済みの行を渡した場合"; {
    z.t.it "宣言suffixの空白を処理して関数名を返す"; {
      z.completion.cache.build.line._function_name $'\t z.example.test()\t {' $'z.example.test()\t {'
      z.t.expect.reply "z.example.test"
    }
  }

  z.t.context "除去済みの行が空の場合"; {
    z.t.it "元の行へ戻らずfalseを返す"; {
      z.completion.cache.build.line._function_name "z.example.test() {" ""
      z.t.expect.status.is.false
    }
  }
}
