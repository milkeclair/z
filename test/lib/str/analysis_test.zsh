source ${z_main}

z.t.describe "z.str.quote"; {
  z.t.context "既定の引用方式の場合"; {
    z.t.it "空白をバックスラッシュで保護する"; {
      z.str.quote "a b"
      z.t.expect.reply 'a\ b'
    }
  }

  z.t.context "引用方式を指定した場合"; {
    z.t.it "それぞれの引用表現を返す"; {
      z.str.quote "a b" style=single
      z.t.expect.reply "'a b'"

      z.str.quote "a b" style=double
      z.t.expect.reply '"a b"'

      z.str.quote "a b" style=ansi
      z.t.expect.reply "\$'a b'"
    }
  }

  z.t.context "入力が空文字やオプションに似た値の場合"; {
    z.t.it "入力を失わず引用する"; {
      z.str.quote "" style=ansi
      z.t.expect.reply "\$''"

      local value="style=double"
      z.str.quote "$value" style=single
      z.t.expect.reply "'style=double'"
    }
  }

  z.t.context "必須引数や引用方式が不正な場合"; {
    z.t.it "失敗する"; {
      z.str.quote # zls: ignore
      z.t.expect.status.is.false

      z.str.quote value style=unknown
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.str.unquote"; {
  z.t.context "引用された単語の場合"; {
    z.t.it "一段の引用を解除する"; {
      z.str.unquote "'a b'"
      z.t.expect.reply "a b"

      z.str.unquote "\$'a\\nb'"
      z.t.expect.reply $'a\nb'

      z.str.unquote "'\"a b\"'"
      z.t.expect.reply '"a b"'
    }
  }

  z.t.context "変数やコマンド置換を含む場合"; {
    z.t.it "展開せず文字列として返す"; {
      local marker=original
      z.str.unquote '"$(marker=changed)$HOME"'
      z.t.expect.reply '$(marker=changed)$HOME'
      z.t.expect "$marker" "original"
    }
  }

  z.t.context "未完の引用を含む場合"; {
    z.t.it "Zshの引用解除と同じ結果を返す"; {
      z.str.unquote "'unfinished"
      z.t.expect.reply "'unfinished"

      z.str.unquote 'a\'
      z.t.expect.reply "a"
    }
  }

  z.t.context "空文字の場合"; {
    z.t.it "空文字を返す"; {
      z.str.unquote ""
      z.t.expect.reply.is.null
    }
  }

  z.t.context "必須引数がない場合"; {
    z.t.it "失敗する"; {
      z.str.unquote # zls: ignore
      z.t.expect.status.is.false
    }
  }
}
