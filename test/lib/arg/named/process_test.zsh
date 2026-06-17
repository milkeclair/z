source ${z_main}

z.t.describe "z.arg.named.shift"; {
  z.t.context "nameが指定されている場合"; {
    z.t.it "name以外の引数を返す"; {
      z.arg.named.shift name name=hoge other=fuga

      z.t.expect.reply other=fuga
    }
  }

  z.t.context "nameを含む別の引数が指定されている場合"; {
    z.t.it "削除対象として扱わない"; {
      z.arg.named.shift name user_name=hoge other=fuga

      z.t.expect.reply.is.arr user_name=hoge other=fuga
    }
  }

  z.t.context "nameが指定されていない場合"; {
    z.t.it "すべての引数を返す"; {
      z.arg.named.shift name name=hoge other=fuga

      z.t.expect.reply other=fuga
    }
  }
}
