source ${z_main}

z.t.describe "z.arg.as"; {
  z.t.context "nameがエイリアスのいずれかに一致する場合"; {
    z.t.it "returnを返す"; {
      z.arg.as name=-h "as=-h|--help" return=0

      z.t.expect.reply 0
    }
  }

  z.t.context "nameがエイリアスのいずれかに一致し、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--help "as=-h|--help"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがエイリアスのいずれにも一致しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--version "as=-h|--help" return=0

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがエイリアスのいずれにも一致せず、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as name=--help "as=-v|--version"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "nameがnullの場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "as=-h|--help" return=0 # zls: ignore

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.arg.named"; {
  z.t.context "nameが指定されている場合"; {
    z.t.it "nameを返す"; {
      z.arg.named name name=hoge other=fuga

      z.t.expect.reply hoge
    }
  }

  z.t.context "nameが指定されていない場合"; {
    z.t.it "nullを返す"; {
      z.arg.named # zls: ignore

      z.t.expect.reply.is.null
    }
  }

  z.t.context "defaultが指定されていて、値がない場合"; {
    z.t.it "デフォルト値を返す"; {
      z.arg.named name name="" other=fuga default=default_value

      z.t.expect.reply default_value
    }
  }

  z.t.context "defaultが指定されていて、値がある場合"; {
    z.t.it "指定された値を返す"; {
      z.arg.named name name=hoge other=fuga default=default_value

      z.t.expect.reply hoge
    }
  }
}
