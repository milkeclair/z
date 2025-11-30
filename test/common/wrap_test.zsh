source ${z_main}

z.t.describe "z.return"; {
  z.t.context "0を指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return 0

      z.t.expect.reply 0
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return "true"

      z.t.expect.reply 0
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return 1

      z.t.expect.reply 1
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return "false"

      z.t.expect.reply 1
    }
  }

  z.t.context "nullを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return

      z.t.expect.reply.null
    }
  }

  z.t.context "voidを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return "void"

      z.t.expect.reply.null
    }
  }

  z.t.context "その他の値を指定した場合"; {
    z.t.it "REPLYにそのままの値を設定する"; {
      z.return "sample_value"

      z.t.expect.reply "sample_value"
    }
  }

  z.t.context "複数の値を指定した場合"; {
    z.t.it "REPLYに配列として設定する"; {
      z.return "value1" "value2" "value3"

      z.t.expect.reply.arr "value1" "value2" "value3"
    }
  }
}

z.t.describe "z.return.hash"; {
  z.t.context "ハッシュが渡された場合"; {
    z.t.it "REPLYにキーと値のペアの配列を設定する"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.return.hash hash
      local -A result=($REPLY)

      z.t.expect ${result[name]} "John"
      z.t.expect ${result[age]} "30"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "REPLYを空に設定する"; {
      local -A empty_hash

      z.return.hash empty_hash

      z.t.expect.reply.null
    }
  }
}
