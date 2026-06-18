source ${z_main}

z.t.describe "z.wtproxy._port.proxy.env.key"; {
  z.t.context "proxy port keyを指定した場合"; {
    z.t.it "proxy port env名を返す"; {
      z.wtproxy._port.proxy.env.key proxy_port_2

      z.t.expect.reply "Z_WTPROXY_PROXY_PORT_2"
    }
  }
}

z.t.describe "z.wtproxy._port.proxy.env.index"; {
  z.t.context "proxy port env名を指定した場合"; {
    z.t.it "indexを返す"; {
      z.wtproxy._port.proxy.env.index Z_WTPROXY_PROXY_PORT_3
      local port_index=$REPLY

      z.t.expect.status.is.true
      z.t.expect "$port_index" 3
    }
  }

  z.t.context "proxy port env名ではない値を指定した場合"; {
    z.t.it "falseを返してREPLYを空にする"; {
      z.wtproxy._port.proxy.env.index Z_WTPROXY_WORKTREE_PORT_3

      z.t.expect.status.is.false
      z.t.expect.reply.is.null
    }
  }
}
