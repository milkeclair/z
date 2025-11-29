source ${z_main}

z.t.describe "z.io.error.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を指定された色で標準エラー出力に出力する"; {
      local output=$(z.io.error.color color=magenta "error message" 2>&1 1>/dev/null)

      z.t.expect $output $'\033[35merror message\033[0m'
    }
  }

  z.t.context "色指定が省略された場合"; {
    z.t.it "赤色で出力する"; {
      local output=$(z.io.error.color "error message" 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31merror message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.color color=red 2>&1 1>/dev/null)

      z.t.expect.null $output
    }
  }
}

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
}

z.t.describe "z.io.error.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 "error message" 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31m      error message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 2>&1 1>/dev/null)

      z.t.expect $output $'\033[31m      \033[0m'
    }
  }
}
