source ${z_main}

z.t.describe "z.arg.named.shift"; {
  z.t.context "nameが指定されている場合"; {
    z.t.it "name以外の引数を返す"; {
      z.arg.named.shift name name=hoge other=fuga

      z.t.expect.reply other=fuga
    }
  }

  z.t.context "nameが指定されていない場合"; {
    z.t.it "すべての引数を返す"; {
      z.arg.named.shift name name=hoge other=fuga

      z.t.expect.reply other=fuga
    }
  }
}
