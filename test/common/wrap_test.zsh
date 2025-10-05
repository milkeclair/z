source ${z_main}

z.t.describe "z.return"; {
  z.t.context "0を指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return 0

      z.t.expect_reply 0
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return "true"

      z.t.expect_reply 0
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return 1

      z.t.expect_reply 1
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return "false"

      z.t.expect_reply 1
    }
  }

  z.t.context "nullを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return

      z.t.expect_reply.null
    }
  }

  z.t.context "voidを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return "void"

      z.t.expect_reply.null
    }
  }

  z.t.context "その他の値を指定した場合"; {
    z.t.it "REPLYにそのままの値を設定する"; {
      z.return "sample_value"

      z.t.expect_reply "sample_value"
    }
  }
}
