source ${z_main}

z.t.describe "z.arg.as"; {
  z.t.context "引数がエイリアスのいずれかに一致する場合"; {
    z.t.it "第三引数を返す"; {
      z.arg.as "-h" "-h|--help" 0

      z.t.expect.reply 0
    }
  }

  z.t.context "引数がエイリアスのいずれかに一致し、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "--help" "-h|--help"

      z.t.expect.reply.null
    }
  }

  z.t.context "引数がエイリアスのいずれにも一致しない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "--version" "-h|--help" 0

      z.t.expect.reply.null
    }
  }

  z.t.context "引数がエイリアスのいずれにも一致せず、第三引数がない場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "--help" "-v|--version"

      z.t.expect.reply.null
    }
  }

  z.t.context "引数がnullの場合"; {
    z.t.it "nullを返す"; {
      z.arg.as "" "-h|--help" 0

      z.t.expect.reply.null
    }
  }
}
