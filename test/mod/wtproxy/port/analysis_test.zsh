source ${z_main}

z.t.describe "z.wtproxy._port.keys"; {
  z.t.context "configが取得できる場合"; {
    z.t.it "configからworktree port keyを返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(proxy_port_1 3000 proxy_port_2 5432)
        z.return.hash config
      '

      z.wtproxy._port.keys

      z.t.expect.reply.is.arr worktree_port_1 worktree_port_2
    }
  }
}

z.t.describe "z.wtproxy._port.proxies"; {
  z.t.context "configが取得できる場合"; {
    z.t.it "proxy portをindex順で返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(proxy_port_2 5432 proxy_port_1 3000)
        z.return.hash config
      '

      z.wtproxy._port.proxies

      z.t.expect.reply.is.arr 3000 5432
    }
  }
}

z.t.describe "z.wtproxy._port.used"; {
  z.t.context "stateにportがある場合"; {
    z.t.it "保存済みportを返す"; {
      z.wtproxy._state.init
      z.wtproxy._state.port.set /tmp/worktree worktree_port_1 13000
      z.wtproxy._state.port.set /tmp/worktree worktree_port_2 15432

      z.wtproxy._port.used
      local ports=("${(@)REPLY}")
      z.arr.sort ${ports[@]}

      z.t.expect.reply.is.arr 13000 15432
    }
  }
}

z.t.describe "z.wtproxy._port.proxy"; {
  z.t.context "worktree port keyを指定した場合"; {
    z.t.it "対応するproxy portを返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(proxy_port_1 3000)
        z.return.hash config
      '

      z.wtproxy._port.proxy worktree_port_1

      z.t.expect.reply 3000
    }
  }

  z.t.context "未知のworktree port keyを指定した場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(proxy_port_1 3000)
        z.return.hash config
      '
      z.t.mock name="z.io.error"

      z.wtproxy._port.proxy worktree_port_2

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "Unknown port key: worktree_port_2"
    }
  }
}
