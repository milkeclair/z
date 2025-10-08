source ${z_main}

z.t.describe "z.arr.count"; {
  z.t.context "配列に要素がある場合"; {
    z.t.it "要素数をREPLYに返す"; {
      z.arr.count "a" "b" "c"

      z.t.expect.reply 3
    }
  }

  z.t.context "配列が空の場合"; {
    z.t.it "0をREPLYに返す"; {
      z.arr.count

      z.t.expect.reply 0
    }
  }
}
