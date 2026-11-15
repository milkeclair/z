source ${z_main}

z.t.describe "z.pj.add._directory"; {
  z.t.context "directoryが存在する場合"; {
    z.t.it "相対パスを絶対パスで返す"; {
      z.pj.add._directory .

      z.t.expect.reply "$PWD"
    }
  }

  z.t.context "directoryを指定しない場合"; {
    z.t.it "失敗する"; {
      z.t.mock name=z.io.error

      z.pj.add._directory ""

      z.t.expect.status.is.false
    }
  }
}
