source "$z_main"

z.t.describe "z.completion.argument.parameter._read"; {
  z.t.context "引数の宣言が正しい場合"; {
    z.t.it "省略可能な名前付き引数と後続の記述を返す"; {
      z.completion.argument.parameter._read '$code? [code]: commands'

      z.t.expect.reply.is.arr named code "[code]: commands"
    }

    z.t.it "位置番号を正規化し、残りの引数も区別する"; {
      z.completion.argument.parameter._read '$01: value'
      z.t.expect.reply.is.arr positional 1 ": value"

      z.completion.argument.parameter._read '$*: values'
      z.t.expect.reply.is.arr rest '*' ": values"
    }
  }

  z.t.context "引数の宣言が不正な場合"; {
    z.t.it "位置0と宣言以外の入力を拒否する"; {
      z.completion.argument.parameter._read '$0: value'
      z.t.expect.status.is.false

      z.completion.argument.parameter._read 'description'
      z.t.expect.status.is.false
    }
  }
}
