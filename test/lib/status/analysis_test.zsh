source ${z_main}

z.t.describe "z.status"; {
  z.t.context "前回のコマンドの終了ステータスが0の場合"; {
    z.t.it "0を返す"; {
      true
      z.status

      z.t.expect.reply 0
    }
  }

  z.t.context "前回のコマンドの終了ステータスが0以外の場合"; {
    z.t.it "0以外の値を返す"; {
      false
      z.status

      z.t.expect.reply 1
    }
  }
}
