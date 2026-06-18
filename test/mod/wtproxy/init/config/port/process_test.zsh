source ${z_main}

z.t.describe "z.wtproxy.init._config.port.value"; {
  z.t.context "引数で値を指定した場合"; {
    z.t.it "引数の値を返す"; {
      z.wtproxy.init._config.port.value proxy_port_1 proxy_port_1=3100

      z.t.expect.reply 3100
    }
  }

  z.t.context "環境変数で値を指定した場合"; {
    z.t.it "環境変数の値を返す"; {
      local Z_WTPROXY_PROXY_PORT_4=8080

      z.wtproxy.init._config.port.value proxy_port_4

      z.t.expect.reply 8080
    }
  }

  z.t.context "引数も環境変数もないdefault keyの場合"; {
    z.t.it "default値を返す"; {
      z.wtproxy.init._config.port.value proxy_port_1

      z.t.expect.reply 3000
    }
  }
}

z.t.describe "z.wtproxy.init._config.port.keys"; {
  z.t.context "追加のproxy port keyがない場合"; {
    z.t.it "default keyをindex順で返す"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=()
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3
    }
  }

  z.t.context "追加のproxy port keyを指定した場合"; {
    z.t.it "default keyと追加keyをindex順で返す"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=()
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys proxy_port_4=8080 proxy_port_5=9000

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3 proxy_port_4 proxy_port_5
    }
  }

  z.t.context "追加のproxy port keyが重複する場合"; {
    z.t.it "重複を除外する"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=()
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys proxy_port_4=8080 proxy_port_4=9000

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3 proxy_port_4
    }
  }

  z.t.context "proxy port keyではない引数がある場合"; {
    z.t.it "proxy port keyだけを返す"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=()
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys force=true worktree_port_4=8080 other=value proxy_port_x=9000 proxy_port_4=8080

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3 proxy_port_4
    }
  }

  z.t.context "環境変数のproxy port keyがある場合"; {
    z.t.it "default keyと環境変数のkeyをindex順で返す"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=(
          proxy_port_2 15432
          proxy_port_6 8080
        )
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3 proxy_port_6
    }
  }

  z.t.context "引数と環境変数のproxy port keyがある場合"; {
    z.t.it "両方のkeyをindex順で返す"; {
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=(
          proxy_port_6 8080
        )
        z.return.hash config
      '

      z.wtproxy.init._config.port.keys proxy_port_4=4000

      z.t.expect.reply.is.arr proxy_port_1 proxy_port_2 proxy_port_3 proxy_port_4 proxy_port_6
    }
  }
}
