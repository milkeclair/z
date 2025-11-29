source ${z_main}

z.t.describe "z.io.warn.indent.color"; {
  z.t.context "色指定が省略された場合"; {
    z.t.it "黄色で出力する"; {
      local output=$(z.io.warn.indent.color level=1 "warn" "detail" 2>/dev/null)

      z.t.expect $output $'  \033[33mwarn\033[0m\n  \033[33mdetail\033[0m'
    }
  }

  z.t.context "color引数が渡された場合"; {
    z.t.it "指定された色で出力する"; {
      local output=$(z.io.warn.indent.color level=2 color=cyan "notice" 2>/dev/null)

      z.t.expect $output $'    \033[36mnotice\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.warn.indent.color level=2 2>/dev/null)

      z.t.expect.null $output
    }
  }
}
