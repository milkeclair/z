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

z.t.describe "z.arr.quote"; {
  z.t.context "引用方式を指定しない場合"; {
    z.t.it "全要素を一括して引用する"; {
      z.arr.quote "a b" "" "c"
      z.t.expect.reply.is.arr 'a\ b' "''" "c"
    }
  }

  z.t.context "引用方式を指定した場合"; {
    z.t.it "空要素やオプションに似た要素も保持する"; {
      z.arr.quote style=ansi "a b" "" "style=double" "default=x"
      z.t.expect.reply.is.arr "\$'a b'" "\$''" "\$'style=double'" "\$'default=x'"

      z.arr.quote style=single "a'b" "x"
      z.t.expect.reply.is.arr "'a'\\''b'" "'x'"

      z.arr.quote style=double '$(print x)' "日本語"
      z.t.expect.reply.is.arr '"\$(print x)"' '"日本語"'
    }
  }

  z.t.context "入力要素がない場合"; {
    z.t.it "空配列を返す"; {
      z.arr.quote
      z.t.expect.reply.is.arr

      z.arr.quote style=ansi
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "nounsetが有効で入力要素がない場合"; {
    z.t.it "未定義の位置引数へアクセスせず空配列を返す"; {
      local result=$(
        setopt nounset
        z.arr.quote
        print -r -- "${#REPLY[@]}"
      )

      z.t.expect "$result" 0
    }
  }

  z.t.context "引用方式が不正な場合"; {
    z.t.it "失敗する"; {
      z.arr.quote style=unknown value
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.arr.unquote"; {
  z.t.context "引用された複数の単語の場合"; {
    z.t.it "空要素と特殊文字を保持する"; {
      z.arr.unquote "'a b'" "''" '"$HOME"' "'style=ansi'" "'日本語'"
      z.t.expect.reply.is.arr "a b" "" '$HOME' "style=ansi" "日本語"
    }
  }

  z.t.context "入力要素がない場合"; {
    z.t.it "空配列を返す"; {
      z.arr.unquote
      z.t.expect.reply.is.arr
    }
  }
}
