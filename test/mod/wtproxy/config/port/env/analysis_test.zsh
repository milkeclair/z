source ${z_main}

z.t.describe "z.wtproxy._config.port.env.values"; {
  z.t.context "proxy port envがある場合"; {
    z.t.it "config keyと値のhashを返す"; {
      local Z_WTPROXY_PROXY_PORT_1=3000
      local Z_WTPROXY_PROXY_PORT_3=5173
      z.t.mock name="z.wtproxy._config.file.key" behavior='
        case $1 in
          Z_WTPROXY_PROXY_PORT_1) z.return proxy_port_1 ;;
          Z_WTPROXY_PROXY_PORT_3) z.return proxy_port_3 ;;
          *) return 1 ;;
        esac
      '

      z.wtproxy._config.port.env.values
      local -A config=("${(@)REPLY}")

      z.t.expect "$config[proxy_port_1]" 3000
      z.t.expect "$config[proxy_port_3]" 5173
    }
  }

  z.t.context "proxy port envがない場合"; {
    z.t.it "空のhashを返す"; {
      z.t.mock name="z.wtproxy._config.file.key" behavior="return 1"

      z.wtproxy._config.port.env.values
      z.t.expect.status.is.true skip_unmock=true
      z.wtproxy._config.port.env.values
      z.t.expect.reply.is.null
    }
  }

  z.t.context "未知のenvがある場合"; {
    z.t.it "configに含めない"; {
      local Z_WTPROXY_WORKTREE_PORT_1=3001
      z.t.mock name="z.wtproxy._config.file.key" behavior="return 1"

      z.wtproxy._config.port.env.values
      z.t.expect.status.is.true skip_unmock=true
      z.wtproxy._config.port.env.values
      z.t.expect.reply.is.null
    }
  }

  z.t.context "proxy port envが空の場合"; {
    z.t.it "configに含めない"; {
      local Z_WTPROXY_PROXY_PORT_1=""
      z.t.mock name="z.wtproxy._config.file.key" behavior='
        z.is.eq "$1" Z_WTPROXY_PROXY_PORT_1 || return 1
        z.return proxy_port_1
      '

      z.wtproxy._config.port.env.values
      z.t.expect.status.is.true skip_unmock=true
      z.wtproxy._config.port.env.values
      z.t.expect.reply.is.null
    }
  }
}
