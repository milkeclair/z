source ${z_main}

z.t.describe "z.wtproxy._port.keys.from_config"; {
  z.t.context "proxy port keyを持つconfigの場合"; {
    z.t.it "対応するworktree port keyをindex順で返す"; {
      local -A config=(
        proxy_port_2 5432
        proxy_port_1 3000
        other value
      )

      z.wtproxy._port.keys.from_config config

      z.t.expect.reply.is.arr worktree_port_1 worktree_port_2
    }
  }

  z.t.context "値が空のproxy port keyがある場合"; {
    z.t.it "空のkeyを除外する"; {
      local -A config=(
        proxy_port_1 3000
        proxy_port_2 ""
        proxy_port_3 5173
      )

      z.wtproxy._port.keys.from_config config

      z.t.expect.reply.is.arr worktree_port_1 worktree_port_3
    }
  }
}
