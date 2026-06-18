source ${z_main}

z.t.describe "z.wtproxy._port.proxy.key"; {
  z.t.context "indexを指定した場合"; {
    z.t.it "proxy port keyを返す"; {
      z.wtproxy._port.proxy.key 2

      z.t.expect.reply "proxy_port_2"
    }
  }
}

z.t.describe "z.wtproxy._port.proxy.index"; {
  z.t.context "proxy port keyを指定した場合"; {
    z.t.it "indexを返す"; {
      z.wtproxy._port.proxy.index proxy_port_12
      local port_index=$REPLY

      z.t.expect.status.is.true
      z.t.expect "$port_index" 12
    }
  }

  z.t.context "proxy port keyではない値を指定した場合"; {
    z.t.it "falseを返してREPLYを空にする"; {
      z.wtproxy._port.proxy.index worktree_port_1

      z.t.expect.status.is.false
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.wtproxy._port.proxy.env"; {
  z.t.context "proxy port keyに対応する環境変数がある場合"; {
    z.t.it "環境変数の値を返す"; {
      local Z_WTPROXY_PROXY_PORT_1=3000

      z.wtproxy._port.proxy.env proxy_port_1

      z.t.expect.reply 3000
    }
  }

  z.t.context "proxy port keyに対応する環境変数がない場合"; {
    z.t.it "REPLYを空にする"; {
      z.wtproxy._port.proxy.env proxy_port_9

      z.t.expect.reply.is.null
    }
  }
}
