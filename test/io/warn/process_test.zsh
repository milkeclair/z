source ${z_main}

z.t.describe "z.io.warn.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を指定された色で標準出力に出力する"; {
      local output=$(z.io.warn.color color=green "warn message" 2>/dev/null)

      z.t.expect $output $'\033[32mwarn message\033[0m'
    }
  }

  z.t.context "色指定が省略された場合"; {
    z.t.it "黄色で出力する"; {
      local output=$(z.io.warn.color "warn message" 2>/dev/null)

      z.t.expect $output $'\033[33mwarn message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.warn.color color=yellow 2>/dev/null)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.warn.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準出力に出力する"; {
      local output=$(z.io.warn.line "warn" "message" 2>/dev/null)

      z.t.expect $output $'\033[33mwarn\nmessage\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.warn.line 2>/dev/null)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.warn.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして標準出力に出力する"; {
      local output=$(z.io.warn.indent level=3 "warn message" 2>/dev/null)

      z.t.expect $output $'\033[33m      warn message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントを標準出力に出力する"; {
      local output=$(z.io.warn.indent level=3 2>/dev/null)

      z.t.expect $output $'\033[33m      \033[0m'
    }
  }
}
