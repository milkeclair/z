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

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arr.split"; {
  z.t.context "区切り文字が指定された場合"; {
    z.t.it "指定された区切り文字で分割された配列を返す"; {
      z.arr.split sep=, "a,b,c"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.split sep=: "one:two:three:four"
      z.t.expect.reply.arr "one" "two" "three" "four"
    }
  }

  z.t.context "区切り文字が指定されなかった場合"; {
    z.t.it "スペースで分割された配列を返す"; {
      z.arr.split "a b c"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.split "one two three four"
      z.t.expect.reply.arr "one" "two" "three" "four"
    }
  }
}

z.t.describe "z.arr.gsub"; {
  z.t.context "検索文字列と置換文字列が指定された場合"; {
    z.t.it "配列要素内の検索文字列が置換文字列に置き換えられた配列を返す"; {
      z.arr.gsub search=a replace=x "a b a" "c a d"
      z.t.expect.reply.arr "x b x" "c x d"

      z.arr.gsub search=one replace=1 "one two one" "three one four"
      z.t.expect.reply.arr "1 two 1" "three 1 four"
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

z.t.describe "z.arr.unique"; {
  z.t.context "重複する要素を含む配列が渡された場合"; {
    z.t.it "重複要素が削除された配列を返す"; {
      z.arr.unique "a" "b" "a" "c" "b"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.unique "1" "2" "2" "3" "1" "4"
      z.t.expect.reply.arr "1" "2" "3" "4"
    }
  }

  z.t.context "重複する要素を含まない配列が渡された場合"; {
    z.t.it "元の配列をそのまま返す"; {
      z.arr.unique "a" "b" "c"
      z.t.expect.reply.arr "a" "b" "c"

      z.arr.unique "1" "2" "3" "4"
      z.t.expect.reply.arr "1" "2" "3" "4"
    }
  }
}

z.t.describe "z.arr.diff"; {
  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "空配列を返す"; {
      local base=("a" "b" "c")
      local other=("a" "b" "c")
      z.arr.diff base="$base" other="$other"

      z.t.expect.reply.null
    }
  }

  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "差分要素を返す"; {
      local base=("a" "b" "c" "d")
      local other=("b" "c" "e" "f")
      z.arr.diff base="$base" other="$other"

      z.t.expect.reply.arr "a" "d" "e" "f"
    }
  }
}

z.t.describe "z.arr.intersect"; {
  z.t.context "共通の要素を持つ配列が渡された場合"; {
    z.t.it "共通要素を返す"; {
      local base=("a" "b" "c" "d")
      local other=("b" "c" "e" "f")
      z.arr.intersect base="$base" other="$other"

      z.t.expect.reply.arr "b" "c"
    }
  }

  z.t.context "共通の要素を持たない配列が渡された場合"; {
    z.t.it "空配列を返す"; {
      local base=("a" "b" "c")
      local other=("d" "e" "f")
      z.arr.intersect base="$base" other="$other"

      z.t.expect.reply.null
    }
  }
}

z.t.describe "z.arr.union"; {
  z.t.context "重複する要素を持つ配列が渡された場合"; {
    z.t.it "重複要素が削除された結合配列を返す"; {
      local base=("a" "b" "c")
      local other=("b" "c" "d" "e")
      z.arr.union base="$base" other="$other"

      z.t.expect.reply.arr "a" "b" "c" "d" "e"
    }
  }

  z.t.context "重複する要素を持たない配列が渡された場合"; {
    z.t.it "結合配列を返す"; {
      local base=("a" "b")
      local other=("c" "d")
      z.arr.union base="$base" other="$other"

      z.t.expect.reply.arr "a" "b" "c" "d"
    }
  }
}
