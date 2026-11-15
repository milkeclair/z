source ${z_main}

z.t.describe "z.arg.named.literal"; {
  z.t.context "文字列の名前付き引数"; {
    z.t.it "trueやnullを含む値をそのまま返す"; {
      local value
      for value in true false null void 0 1 '/tmp/a b\c'; do
        z.arg.named.literal name "name=$value"

        z.t.expect.reply "$value"
      done
    }

    z.t.it "最初の完全一致を使い値の等号を残す"; {
      z.arg.named.literal name user_name=other 'name=a=b c' name=second

      z.t.expect.reply 'a=b c'
    }
  }

  z.t.context "値がない場合"; {
    z.t.it "未指定と明示された空文字を空で返す"; {
      z.arg.named.literal name other=value
      local missing=$REPLY
      z.arg.named.literal name name= name=second
      local empty=$REPLY

      z.t.expect "$missing" ""
      z.t.expect "$empty" ""
    }
  }
}
