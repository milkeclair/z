source ${z_main}

z.t.describe "z.io.indent.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして指定された色で出力する"; {
      local output=$(z.io.indent.color level=2 color=red "indented message")

      z.t.expect $output $'    \033[31mindented message\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.indent.color level=2 color=red)

      z.t.expect.null $output
    }
  }
}
