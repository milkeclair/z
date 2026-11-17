source "$z_main"

z.t.describe "z.completion.argument.type._read"; {
  z.t.context "code型アノテーションが正しい場合"; {
    z.t.it "型と選択肢の後ろにある説明を保持する"; {
      z.completion.argument.type._read "[code | 'call_original' | 'a:b c']: commands"

      z.t.expect.reply.is.arr ": commands" call_original "a:b c"
    }

    z.t.it "許可値なしと空の許可値を区別する"; {
      z.completion.argument.type._read "[code]: commands"
      z.t.expect.reply.is.arr ": commands"

      z.completion.argument.type._read "[code | '']: commands"
      z.t.expect.reply.is.arr ": commands" ""
    }
  }

  z.t.context "型アノテーションが不正な場合"; {
    z.t.it "不完全な型と未知の型を拒否する"; {
      z.completion.argument.type._read "[code | 'missing'"
      z.t.expect.status.is.false

      z.completion.argument.type._read "[other]: commands"
      z.t.expect.status.is.false
    }
  }
}
