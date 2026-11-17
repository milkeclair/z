source ${z_main}

z.t.describe "z.str.split.shell"; {
  z.t.context "通常のコマンド文字列の場合"; {
    z.t.it "引用を保った単語と演算子を返す"; {
      z.str.split.shell 'print "a b"; next'
      z.t.expect.reply.is.arr "print" '"a b"' ";" "next"
    }
  }

  z.t.context "コメントと改行の指定がない場合"; {
    z.t.it "コメントも単語とし改行を区切りにする"; {
      z.str.split.shell $'print x # note\nlast'
      z.t.expect.reply.is.arr "print" "x" "#" "note" ";" "last"
    }
  }

  z.t.context "コメントの扱いを指定した場合"; {
    z.t.it "コメントを保持または除去する"; {
      z.str.split.shell $'print x # note\nlast' comments=keep
      z.t.expect.reply.is.arr "print" "x" "# note" ";" "last"

      z.str.split.shell $'print x # note\nlast' comments=drop
      z.t.expect.reply.is.arr "print" "x" ";" "last"
    }
  }

  z.t.context "改行を空白として扱う場合"; {
    z.t.it "区切りトークンを追加しない"; {
      z.str.split.shell $'print x # note\nlast' comments=keep newlines=whitespace
      z.t.expect.reply.is.arr "print" "x" "# note" "last"

      z.str.split.shell $'print x # note\nlast' comments=drop newlines=whitespace
      z.t.expect.reply.is.arr "print" "x" "last"

      z.str.split.shell $'print x\nlast' newlines=whitespace
      z.t.expect.reply.is.arr "print" "x" "last"
    }
  }

  z.t.context "引用内に改行や置換式がある場合"; {
    z.t.it "文字列を実行せず引用を維持する"; {
      z.str.split.shell $'print "a\nb" $(print x)'
      z.t.expect.reply.is.arr "print" $'"a\nb"' '$(print x)'
    }
  }

  z.t.context "入力が空の場合"; {
    z.t.it "空配列を返す"; {
      z.str.split.shell ""
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "入力やオプションが不正な場合"; {
    z.t.it "失敗する"; {
      z.str.split.shell # zls: ignore
      z.t.expect.status.is.false

      z.str.split.shell x comments=unknown
      z.t.expect.status.is.false

      z.str.split.shell x newlines=unknown
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.split.line"; {
  z.t.context "空行と末尾改行がある場合"; {
    z.t.it "全ての空要素を保持する"; {
      z.str.split.line $'a\n\nb\n'
      z.t.expect.reply.is.arr "a" "" "b" ""
    }
  }

  z.t.context "空文字の場合"; {
    z.t.it "一つの空要素を返す"; {
      z.str.split.line ""
      z.t.expect.reply.is.arr ""
    }
  }

  z.t.context "空行を除去する場合"; {
    z.t.it "空白だけの行は保持する"; {
      z.str.split.line $'\na\n\n \nb\n' empty=drop
      z.t.expect.reply.is.arr "a" " " "b"

      z.str.split.line "" empty=drop
      z.t.expect.reply.is.arr
    }
  }

  z.t.context "入力がオプションに似ている場合"; {
    z.t.it "先頭の文字列を入力として扱う"; {
      local value="empty=drop"
      z.str.split.line "$value" empty=keep
      z.t.expect.reply.is.arr "empty=drop"
    }
  }

  z.t.context "入力や指定値が不正な場合"; {
    z.t.it "失敗する"; {
      z.str.split.line # zls: ignore
      z.t.expect.status.is.false

      z.str.split.line x empty=unknown
      z.t.expect.status.is.false
    }
  }
}
