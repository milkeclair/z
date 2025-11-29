source ${z_main}

z.t.describe "z.io.success.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を指定された色で標準出力に出力する"; {
      local output=$(z.io.success.color green "success message" 2>/dev/null)

      z.t.expect $output $'\033[32msuccess message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success.color green 2>/dev/null)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.success.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準出力に出力する"; {
      local output=$(z.io.success.line "success" "message" 2>/dev/null)

      z.t.expect $output $'\033[32msuccess\nmessage\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "空行を出力する"; {
      local output=$(z.io.success.line 2>/dev/null)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.success.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして標準出力に出力する"; {
      local output=$(z.io.success.indent level=3 "success message" 2>/dev/null)

      z.t.expect $output $'\033[32m      success message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを標準出力に出力する"; {
      local output=$(z.io.success.indent level=3 "success" 2>/dev/null)

      z.t.expect $output $'\033[32m      success\033[0m'
    }
  }
}
