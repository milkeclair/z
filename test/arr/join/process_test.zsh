source ${z_main}

z.t.describe "z.arr.join.line"; {
  z.t.context "複数の引数が渡された場合"; {
    z.t.it "引数を改行区切りで連結してREPLYに格納する"; {
      z.arr.join.line "a" "b" "c"

      z.t.expect.reply $'a\nb\nc'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "REPLYを空文字列に設定する"; {
      z.arr.join.line

      z.t.expect.reply.is.null
    }
  }
}
