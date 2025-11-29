source ${z_main}

z.t.describe "z.io.error.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準エラー出力に出力する"; {
      local output=$(z.io.error.line "error" "message" 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31merror\nmessage\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.line 2>&1 1>/dev/null)

      z.t.expect.null $output
    }
  }

  z.t.context "colorオプションが指定された場合"; {
    z.t.it "引数を指定された色で標準エラー出力に出力する"; {
      local output=$(z.io.error.line "Custom" "error" "message" color=cyan 2>&1 1>/dev/null)

      z.t.expect $output $'\033[36mCustom\nerror\nmessage\033[0m'
    }
  }

  z.t.context "indentオプションが指定された場合"; {
    z.t.it "引数を指定されたインデントレベルで標準エラー出力に出力する"; {
      local output=$(z.io.error.line "Indented" "error" "message" indent=2 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31m    Indented\n    error\n    message\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが両方指定された場合"; {
    z.t.it "引数を指定された色とインデントレベルで標準エラー出力に出力する"; {
      local output=$(z.io.error.line "Colored" "and" "indented" color=magenta indent=3 2>&1 1>/dev/null)

      z.t.expect $output $'\033[35m      Colored\n      and\n      indented\033[0m'
    }
  }

  z.t.context "colorオプションとindentオプションが指定され、引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.line color=magenta indent=3 2>&1 1>/dev/null)

      z.t.expect.null $output
    }
  }
}

