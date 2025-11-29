source ${z_main}

z.t.describe "z.io.success.indent.color"; {
  z.t.context "色指定が省略された場合"; {
    z.t.it "緑色で出力する"; {
      local output=$(z.io.success.indent.color level=2 "success" "done" 2>/dev/null)

      z.t.expect $output $'    \033[32msuccess\033[0m\n    \033[32mdone\033[0m'
    }
  }

  z.t.context "color引数が渡された場合"; {
    z.t.it "指定された色で出力する"; {
      local output=$(z.io.success.indent.color level=1 color=magenta "ok" 2>/dev/null)

      z.t.expect $output $'  \033[35mok\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.success.indent.color level=1 2>/dev/null)

      z.t.expect.null $output
    }
  }
}
