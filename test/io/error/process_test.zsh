source ${z_main}

z.t.describe "z.io.error.line"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を改行区切りで標準エラー出力に出力する"; {
      local output=$(z.io.error.line "error" "message" 2>&1 1>/dev/null)

      z.t.expect $output $'error\nmessage'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.line 2>&1 1>/dev/null)

      z.t.expect $output ""
    }
  }
}

z.t.describe "z.io.error.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 "error message" 2>&1 1>/dev/null)

      z.t.expect $output "      error message"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを標準エラー出力に出力する"; {
      local output=$(z.io.error.indent level=3 "error" 2>&1 1>/dev/null)

      z.t.expect $output "      error"
    }
  }
}
