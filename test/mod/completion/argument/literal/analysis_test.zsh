source "$z_main"

z.t.describe "z.completion.argument.literal._read"; {
  z.t.context "引用された許可値がある場合"; {
    z.t.it "コロンや空白を含む値と後続のアノテーションを返す"; {
      z.completion.argument.literal._read "'a:b c' | 'other']"

      z.t.expect.reply.is.arr "a:b c" " | 'other']"
    }

    z.t.it "引用符とバックスラッシュのescapeを復号する"; {
      z.completion.argument.literal._read "'a\\'b' tail"
      z.t.expect.reply.is.arr "a'b" " tail"

      z.completion.argument.literal._read "'a\\\\b']"
      z.t.expect.reply.is.arr 'a\b' "]"
    }

    z.t.it "空の許可値を配列の要素として保持する"; {
      z.completion.argument.literal._read "'' ]"

      z.t.expect.reply.is.arr "" " ]"
    }
  }

  z.t.context "引用が不完全または省略されている場合"; {
    z.t.it "閉じていない引用と引用なしの値を拒否する"; {
      z.completion.argument.literal._read "'missing"
      z.t.expect.status.is.false

      z.completion.argument.literal._read "bare"
      z.t.expect.status.is.false
    }
  }
}
