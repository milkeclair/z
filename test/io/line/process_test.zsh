source ${z_main}

z.t.describe "z.io.line.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を指定された色で改行区切りにして出力する"; {
      local output=$(z.io.line.color blue "hello" "world")

      z.t.expect $output $'\033[34mhello\nworld\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "空行を出力する"; {
      local output=$(z.io.line.color blue)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.line.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで各行をインデントして出力する"; {
      local output=$(z.io.line.indent level=2 "hello" "world")

      z.t.expect $output $'    hello\n    world'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを出力する"; {
      local output=$(z.io.line.indent level=2)

      z.t.expect $output "    "
    }
  }
}
