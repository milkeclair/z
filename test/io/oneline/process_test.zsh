source ${z_main}

z.t.describe "z.io.oneline.color"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "引数を指定された色で改行なしで出力する"; {
      local output=$(z.io.oneline.color red "hello" "world")

      z.t.expect $output $'\033[31mhello world\033[0m'
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "何も出力しない"; {
      local output=$(z.io.oneline.color red)

      z.t.expect.null $output
    }
  }
}

z.t.describe "z.io.oneline.indent"; {
  z.t.context "引数が渡された場合"; {
    z.t.it "指定されたインデントレベルで引数をインデントして改行なしで出力する"; {
      local output=$(z.io.oneline.indent level=2 "hello" "world")

      z.t.expect $output "    hello world"
    }
  }

  z.t.context "引数が渡されなかった場合"; {
    z.t.it "インデントのみを出力する"; {
      local output=$(z.io.oneline.indent level=2)

      z.t.expect $output "    "
    }
  }
}
