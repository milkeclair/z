source "$z_main"

z.t.describe "z.t._log.format"; {
  z.t.context "通常の見出し"; {
    z.t.it "字下げと色を付ける"; {
      z.t._log.format "  " green "見出し"

      z.t.expect.reply $'\033[32m  見出し\033[0m'
    }
  }

  z.t.context "色付き・複数行の見出し"; {
    z.t.it "既存の色を除去し先頭だけ字下げする"; {
      z.t._log.format "    " yellow $'\033[31mfirst\nsecond\033[0m'

      z.t.expect.reply $'\033[33m    first\nsecond\033[0m'
    }
  }

  z.t.context "戻り値の正規化を含む見出し"; {
    z.t.it "従来の整形処理と一致する"; {
      for message in "" true false null void 0 1 keep_empty=true keep_empty=false "message=value" "default=value" $'a\\b\tc'; do
        z.str.indent level=3 message="$message"
        z.str.color.red "$REPLY"
        local expected=$REPLY

        z.t._log.format "      " red "$message"

        z.t.expect.reply "$expected"
      done
    }
  }

  z.t.context "不明な色"; {
    z.t.it "色を付けず既存の色を除去する"; {
      z.t._log.format "  " unknown $'\033[32mmessage\033[0m'

      z.t.expect.reply "  message"
    }
  }

  z.t.context "色パレットを変更した場合"; {
    z.t.it "登録されたコードを使って整形する"; {
      local observed=$(
        () {
          local -A z_color_palette=(red "<red>" green "<green>" reset "</>")
          z.t._log.format "  " green "<red>message</>"

          print -r -- "$REPLY"
        }
      )

      z.t.expect "$observed" "<green>  message</>"
    }
  }

  z.t.context "引数がない場合"; {
    z.t.it "空の値を返す"; {
      z.t._log.format # zls: ignore

      z.t.expect.reply.is.null
    }
  }
}
