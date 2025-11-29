source ${z_main}

z.t.describe "z.io.error.indent.color"; {
  z.t.context "色指定が省略された場合"; {
    z.t.it "赤色で出力する"; {
      local output=$(z.io.error.indent.color level=2 "error" "details" 2>&1 1>/dev/null) # zls: ignore

      z.t.expect $output $'    \033[31merror\033[0m\n    \033[31mdetails\033[0m'
    }
  }

  z.t.context "color引数が渡された場合"; {
    z.t.it "指定された色で出力する"; {
      local output=$(z.io.error.indent.color level=1 color=yellow "warn" 2>&1 1>/dev/null)

      z.t.expect $output $'  \033[33mwarn\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.error.indent.color level=2 2>&1 1>/dev/null) # zls: ignore

      z.t.expect.null $output
    }
  }
}
