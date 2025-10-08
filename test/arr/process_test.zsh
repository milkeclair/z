source ${z_main}

z.t.describe "z.arr.join"; {
  z.t.context "配列要素が渡された場合"; {
    z.t.it "要素がスペースで結合された文字列を返す"; {
      z.arr.join "a" "b" "c"
      z.t.expect.reply "a b c"

      z.arr.join "one" "two" "three" "four"
      z.t.expect.reply "one two three four"
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "空文字列を返す"; {
      z.arr.join
      z.t.expect.reply ""
    }
  }
}
