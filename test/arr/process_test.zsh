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

z.t.describe "z.arr.sort"; {
  z.t.context "昇順指定で配列要素が渡された場合"; {
    z.t.it "昇順に並べ替えられた要素が返る"; {
      z.arr.sort by=asc "b" "c" "a"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.sort by=asc "5" "3" "1"
      z.t.expect.reply.arr "1" "3" "5"

      z.arr.sort by=asc "b" "1" "a" "4" "c"
      z.t.expect.reply.arr "1" "4" "a" "b" "c"
    }
  }

  z.t.context "降順指定で配列要素が渡された場合"; {
    z.t.it "降順に並べ替えられた要素が返る"; {
      z.arr.sort by=desc "b" "c" "a"
      z.t.expect.reply.arr "c" "b" "a"

      z.arr.sort by=desc "1" "3" "5"
      z.t.expect.reply.arr "5" "3" "1"

      z.arr.sort by=desc "b" "1" "a" "4" "c"
      z.t.expect.reply.arr "c" "b" "a" "4" "1"
    }
  }

  z.t.context "並べ替え順が指定されなかった場合"; {
    z.t.it "昇順に並べ替えられた要素が返る"; {
      z.arr.sort "b" "c" "a"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.sort "5" "3" "1"
      z.t.expect.reply.arr "1" "3" "5"

      z.arr.sort "b" "1" "a" "4" "c"
      z.t.expect.reply.arr "1" "4" "a" "b" "c"
    }
  }

  z.t.context "無効な並べ替え順が指定された場合"; {
    z.t.it "エラーメッセージを出力する"; {
      z.t.mock name=z.io.error behavior="REPLY=\$1"

      z.arr.sort by=invalid "a" "b" "c"

      z.t.expect.reply "z.arr.sort: invalid sort order: invalid"
    }

    z.t.it "終了ステータス1を返す"; {
      z.t.mock name=z.io.error

      z.arr.sort by=invalid "a" "b" "c"

      z.t.expect.status 1
    }

    z.t.it "配列要素をそのまま返す"; {
      z.t.mock name=z.io.error

      z.arr.sort by=invalid "a" "c" "b"

      z.t.expect.reply.arr "a" "c" "b"
    }
  }
}
