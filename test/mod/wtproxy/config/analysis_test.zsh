source ${z_main}

z.t.describe "z.wtproxy._config"; {
  z.t.context "default projectが取得できる場合"; {
    z.t.it "state関連pathを含むconfigを返す"; {
      local XDG_STATE_HOME=/tmp/z_t/state_home
      z.t.mock name="z.wtproxy._config.values" behavior='
        local -A config=(proxy_port_1 3000)
        z.return.hash config
      '
      z.t.mock name="z.wtproxy._config.file.default_project" behavior="z.return sample"

      z.wtproxy._config
      local -A config=("${(@)REPLY}")

      z.t.expect "$config[project]" sample
      z.t.expect "$config[host]" 127.0.0.1
      z.t.expect "$config[state_dir]" /tmp/z_t/state_home/wtproxy
      z.t.expect "$config[state_file]" /tmp/z_t/state_home/wtproxy/sample.state
      z.t.expect "$config[proxy_port_1]" 3000
    }
  }

  z.t.context "default projectが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._config.values" behavior='
        local -A config=()
        z.return.hash config
      '
      z.t.mock name="z.wtproxy._config.file.default_project" behavior="return 1"
      z.t.mock name="z.io.error"

      z.wtproxy._config

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "git worktree root is required"
    }
  }
}

z.t.describe "z.wtproxy._config.value"; {
  z.t.context "config keyを指定した場合"; {
    z.t.it "configの値を返す"; {
      z.t.mock name="z.wtproxy._config" behavior='
        local -A config=(state_file /tmp/sample.state)
        z.return.hash config
      '

      z.wtproxy._config.value state_file

      z.t.expect.reply /tmp/sample.state
    }
  }
}

z.t.describe "z.wtproxy._config.values"; {
  z.t.context "file configとenv configがある場合"; {
    z.t.it "default, file, envの順で上書きする"; {
      z.t.mock name="z.wtproxy._config.file.values" behavior='
        local -A config=(proxy_port_1 3100 proxy_port_4 8080)
        z.return.hash config
      '
      z.t.mock name="z.wtproxy._config.port.env.values" behavior='
        local -A config=(proxy_port_1 3200)
        z.return.hash config
      '

      z.wtproxy._config.values
      local -A config=("${(@)REPLY}")

      z.t.expect "$config[proxy_port_1]" 3200
      z.t.expect "$config[proxy_port_2]" 5432
      z.t.expect "$config[proxy_port_3]" 5173
      z.t.expect "$config[proxy_port_4]" 8080
    }
  }
}
