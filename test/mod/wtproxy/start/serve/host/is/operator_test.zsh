source ${z_main}

z.t.describe "z.wtproxy.start._serve.host.is.localhost"; {
  z.t.context "localhost hostを指定した場合"; {
    z.t.it "trueを返す"; {
      z.wtproxy.start._serve.host.is.localhost localhost
      z.t.expect.status.is.true

      z.wtproxy.start._serve.host.is.localhost 127.0.0.2
      z.t.expect.status.is.true
    }
  }

  z.t.context "localhostではないhostを指定した場合"; {
    z.t.it "falseを返す"; {
      z.wtproxy.start._serve.host.is.localhost 192.168.1.1

      z.t.expect.status.is.false
    }
  }
}
