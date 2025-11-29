source ${z_main}

z.t.describe "z.io.line.indent.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "各行をインデントして指定された色で出力する"; {
      local output=$(z.io.line.indent.color level=2 color=green "hello" "world")

      z.t.expect $output $'    \033[32mhello\033[0m\n    \033[32mworld\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.line.indent.color level=2 color=green)

      z.t.expect.null $output
    }
  }
}
