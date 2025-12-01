source ${z_main}

z.t.describe "z.io.success.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準出力に出力する"; {
      local output=$(z.io.success.line "success" "message" 2>/dev/null)

      z.t.expect $output $'\033[32msuccess\nmessage\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success.line 2>/dev/null)

      z.t.expect.is.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で標準出力に出力する"; {
      local output=$(z.io.success.line "Custom" "success" "message" color=cyan 2>/dev/null)

      z.t.expect $output $'\033[36mCustom\nsuccess\nmessage\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで標準出力に出力する"; {
      local output=$(z.io.success.line "Indented" "success" "message" indent=2 2>/dev/null)

      z.t.expect $output $'\033[32m    Indented\n    success\n    message\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで標準出力に出力する"; {
      local output=$(z.io.success.line "Colored" "and" "indented" color=magenta indent=3 2>/dev/null)

      z.t.expect $output $'\033[35m      Colored\n      and\n      indented\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success.line color=magenta indent=3 2>/dev/null)

      z.t.expect.is.null $output
    }
  }
}
