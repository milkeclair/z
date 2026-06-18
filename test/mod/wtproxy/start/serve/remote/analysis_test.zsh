source ${z_main}

z.t.describe "z.wtproxy.start._serve.remote.host"; {
  z.t.context "fdに対応するztcp -L行がある場合"; {
    z.t.it "remote hostを返す"; {
      z.t.mock name="ztcp" behavior='
        z.io "11 4 127.0.0.1 3000 127.0.0.1 50000"
        z.io "12 4 127.0.0.1 3000 192.168.1.10 50001"
      '

      z.wtproxy.start._serve.remote.host 12

      z.t.expect.reply 192.168.1.10
    }
  }

  z.t.context "fdに対応するztcp -L行がない場合"; {
    z.t.it "REPLYを空にする"; {
      z.t.mock name="ztcp" behavior="z.io '11 4 127.0.0.1 3000 127.0.0.1 50000'"

      z.wtproxy.start._serve.remote.host 99

      z.t.expect.reply.is.null
    }
  }
}
