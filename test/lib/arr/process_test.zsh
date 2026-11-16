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

      z.t.expect.reply.is.null
    }
  }

  z.t.context "区切り文字が指定された場合"; {
    z.t.it "指定された区切り文字で結合された文字列を返す"; {
      z.arr.join delimiter="," "a" "b" "c"
      z.t.expect.reply "a,b,c"

      z.arr.join delimiter=":" "one" "two" "three" "four"
      z.t.expect.reply "one:two:three:four"
    }
  }

  z.t.context "空要素や名前付き引数に見えるデータが渡された場合"; {
    z.t.it "従来どおり空要素を除き、未知の名前をデータとして結合する"; {
      z.arr.join "" "a b" "" "input=value" "named=value" "rest=value" "default=x" ""
      z.t.expect.reply "a b input=value named=value rest=value default=x"
    }
  }

  z.t.context "同じ区切り文字の指定が複数ある場合"; {
    z.t.it "最初の指定を使い、後の指定も結合対象から除く"; {
      z.arr.join "a" delimiter=, "b" delimiter=: "c"
      z.t.expect.reply "a,b,c"
    }
  }

  z.t.context "区切り文字が空値またはnullの場合"; {
    z.t.it "既定のスペースを使う"; {
      z.arr.join delimiter= "a" "b"
      z.t.expect.reply "a b"

      z.arr.join delimiter=null "a" "b"
      z.t.expect.reply "a b"
    }
  }

  z.t.context "区切り文字が真偽値の場合"; {
    z.t.it "従来の数値変換を維持する"; {
      z.arr.join delimiter=true "a" "b"
      z.t.expect.reply "a0b"

      z.arr.join delimiter=false "a" "b"
      z.t.expect.reply "a1b"
    }
  }

  z.t.context "区切り文字が複数文字の場合"; {
    z.t.it "IFSの先頭文字で結合する"; {
      z.arr.join delimiter="::" "a" "b"
      z.t.expect.reply "a:b"
    }
  }

  z.t.context "残りの引数が単独の真偽値またはnullの場合"; {
    z.t.it "従来の戻り値変換を維持する"; {
      z.arr.join true
      z.t.expect.reply 0

      z.arr.join false
      z.t.expect.reply 1

      z.arr.join null
      z.t.expect.reply.is.null
    }
  }

  z.t.context "keep_empty指定を含む場合"; {
    z.t.it "従来どおり戻り値オプションとして扱う"; {
      z.arr.join keep_empty=true "a" "" "b"
      z.t.expect.reply "a b"
    }
  }

  z.t.context "空白、改行、日本語を含む要素が渡された場合"; {
    z.t.it "要素の内容と呼び出し元のIFSを保持する"; {
      local IFS=":"
      z.arr.join "a b" $'c\nd' 日本語 delimiter=,
      local result_code=$?
      local result_reply=$REPLY
      local result_ifs=$IFS

      z.t.expect "$result_reply" $'a b,c\nd,日本語'
      z.t.expect "$result_code" 0
      z.t.expect "$result_ifs" ":"
    }
  }
}

z.t.describe "z.arr.split"; {
  z.t.context "区切り文字が指定された場合"; {
    z.t.it "指定された区切り文字で分割された配列を返す"; {
      z.arr.split delimiter=, "a,b,c"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.split delimiter=: "one:two:three:four"
      z.t.expect.reply.is.arr "one" "two" "three" "four"
    }
  }

  z.t.context "区切り文字が指定されなかった場合"; {
    z.t.it "スペースで分割された配列を返す"; {
      z.arr.split "a b c"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.split "one two three four"
      z.t.expect.reply.is.arr "one" "two" "three" "four"
    }
  }
}

z.t.describe "z.arr.gsub"; {
  z.t.context "検索文字列と置換文字列が指定された場合"; {
    z.t.it "配列要素内の検索文字列が置換文字列に置き換えられた配列を返す"; {
      z.arr.gsub "a b a" "c a d" search=a replace=x
      z.t.expect.reply.is.arr "x b x" "c x d"

      z.arr.gsub "one two one" "three one four" search=one replace=1
      z.t.expect.reply.is.arr "1 two 1" "three 1 four"
    }
  }
}

z.t.describe "z.arr.sort"; {
  z.t.context "昇順指定で配列要素が渡された場合"; {
    z.t.it "昇順に並べ替えられた要素が返る"; {
      z.arr.sort by=asc "b" "c" "a"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.sort by=asc "5" "3" "1"
      z.t.expect.reply.is.arr "1" "3" "5"

      z.arr.sort by=asc "b" "1" "a" "4" "c"
      z.t.expect.reply.is.arr "1" "4" "a" "b" "c"
    }
  }

  z.t.context "降順指定で配列要素が渡された場合"; {
    z.t.it "降順に並べ替えられた要素が返る"; {
      z.arr.sort by=desc "b" "c" "a"
      z.t.expect.reply.is.arr "c" "b" "a"

      z.arr.sort by=desc "1" "3" "5"
      z.t.expect.reply.is.arr "5" "3" "1"

      z.arr.sort by=desc "b" "1" "a" "4" "c"
      z.t.expect.reply.is.arr "c" "b" "a" "4" "1"
    }
  }

  z.t.context "並べ替え順が指定されなかった場合"; {
    z.t.it "昇順に並べ替えられた要素が返る"; {
      z.arr.sort "b" "c" "a"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.sort "5" "3" "1"
      z.t.expect.reply.is.arr "1" "3" "5"

      z.arr.sort "b" "1" "a" "4" "c"
      z.t.expect.reply.is.arr "1" "4" "a" "b" "c"
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

      z.t.expect.reply.is.arr "a" "c" "b"
    }
  }
}

z.t.describe "z.arr.unique"; {
  z.t.context "重複する要素を含む配列が渡された場合"; {
    z.t.it "重複要素が削除された配列を返す"; {
      z.arr.unique "a" "b" "a" "c" "b"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.unique "1" "2" "2" "3" "1" "4"
      z.t.expect.reply.is.arr "1" "2" "3" "4"
    }
  }

  z.t.context "重複する要素を含まない配列が渡された場合"; {
    z.t.it "元の配列をそのまま返す"; {
      z.arr.unique "a" "b" "c"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.unique "1" "2" "3" "4"
      z.t.expect.reply.is.arr "1" "2" "3" "4"
    }
  }

  z.t.context "値がfalse、null、パス風文字列の場合"; {
    z.t.it "要素名を真偽判定せず、内部集合の所属で処理する"; {
      z.arr.unique false null ./missing false null ./missing
      local -a result=("${REPLY[@]}")

      z.t.expect "${#result[@]}" 3
      z.t.expect "${result[1]}" "false"
      z.t.expect "${result[2]}" "null"
      z.t.expect "${result[3]}" "./missing"
    }
  }
}

z.t.describe "z.arr.diff"; {
  z.t.context "同じ要素を持つ配列が渡された場合"; {
    z.t.it "空配列を返す"; {
      local base=("a" "b" "c")
      local other=("a" "b" "c")
      z.arr.diff base="$base" other="$other"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "異なる要素を持つ配列が渡された場合"; {
    z.t.it "差分要素を返す"; {
      local base=("a" "b" "c" "d")
      local other=("b" "c" "e" "f")
      z.arr.diff base="$base" other="$other"

      z.t.expect.reply.is.arr "a" "d" "e" "f"
    }
  }
}

z.t.describe "z.arr.intersect"; {
  z.t.context "共通の要素を持つ配列が渡された場合"; {
    z.t.it "共通要素を返す"; {
      local base=("a" "b" "c" "d")
      local other=("b" "c" "e" "f")
      z.arr.intersect base="$base" other="$other"

      z.t.expect.reply.is.arr "b" "c"
    }
  }

  z.t.context "共通の要素を持たない配列が渡された場合"; {
    z.t.it "空配列を返す"; {
      local base=("a" "b" "c")
      local other=("d" "e" "f")
      z.arr.intersect base="$base" other="$other"

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.arr.union"; {
  z.t.context "重複する要素を持つ配列が渡された場合"; {
    z.t.it "重複要素が削除された結合配列を返す"; {
      local base=("a" "b" "c")
      local other=("b" "c" "d" "e")
      z.arr.union base="$base" other="$other"

      z.t.expect.reply.is.arr "a" "b" "c" "d" "e"
    }
  }

  z.t.context "重複する要素を持たない配列が渡された場合"; {
    z.t.it "結合配列を返す"; {
      local base=("a" "b")
      local other=("c" "d")
      z.arr.union base="$base" other="$other"

      z.t.expect.reply.is.arr "a" "b" "c" "d"
    }
  }
}

z.t.describe "z.arr.reverse"; {
  z.t.context "配列要素が渡された場合"; {
    z.t.it "要素が逆順に並んだ配列を返す"; {
      z.arr.reverse "a" "b" "c"
      z.t.expect.reply.is.arr "c" "b" "a"

      z.arr.reverse "one" "two" "three" "four"
      z.t.expect.reply.is.arr "four" "three" "two" "one"
    }
  }

  z.t.context "配列要素が渡されなかった場合"; {
    z.t.it "空配列を返す"; {
      z.arr.reverse

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.arr.slice"; {
  z.t.context "offsetとtoが指定された場合"; {
    z.t.it "offsetからtoまでの要素を返す"; {
      z.arr.slice offset=2 to=4 "a" "b" "c" "d" "e"
      z.t.expect.reply.is.arr "c" "d"

      z.arr.slice offset=1 to=4 "one" "two" "three" "four" "five"
      z.t.expect.reply.is.arr "two" "three" "four"
    }
  }

  z.t.context "offsetが指定され、toが指定されなかった場合"; {
    z.t.it "offsetから最後までの要素を返す"; {
      z.arr.slice offset=3 "a" "b" "c" "d" "e"
      z.t.expect.reply.is.arr "d" "e"

      z.arr.slice offset=2 "one" "two" "three" "four" "five"
      z.t.expect.reply.is.arr "three" "four" "five"
    }
  }

  z.t.context "offsetが指定されなかった場合"; {
    z.t.it "最初からtoまでの要素を返す"; {
      z.arr.slice to=3 "a" "b" "c" "d" "e"
      z.t.expect.reply.is.arr "a" "b" "c"

      z.arr.slice to=4 "one" "two" "three" "four" "five"
      z.t.expect.reply.is.arr "one" "two" "three" "four"
    }
  }
}
