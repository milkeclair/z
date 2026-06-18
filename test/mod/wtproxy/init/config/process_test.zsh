source ${z_main}

z.t.describe "z.wtproxy.init._config.content"; {
  z.t.context "proxy portを指定した場合"; {
    z.t.it "proxy port env名で初期設定内容を作る"; {
      z.wtproxy.init._config.content proxy_port_1=3100 proxy_port_4=8080
      local content=$REPLY

      z.t.expect.includes "$content" "Z_WTPROXY_PROXY_PORT_1=3100"
      z.t.expect.includes "$content" "Z_WTPROXY_PROXY_PORT_4=8080"
    }
  }
}

z.t.describe "z.wtproxy.init._config.file"; {
  z.t.context "config fileが存在しない場合"; {
    z.t.it "config fileを作成する"; {
      local config_file=/tmp/z_t/wtproxy_init_config/sample.env
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return $config_file"
      z.t.mock name="z.wtproxy.init._config.content" behavior="z.return 'Z_WTPROXY_PROXY_PORT_1=3000'"

      local result=$(z.wtproxy.init._config.file)
      local content=$(cat $config_file)

      z.t.expect "$result" "created: $config_file"
      z.t.expect "$content" "Z_WTPROXY_PROXY_PORT_1=3000"
    }
  }

  z.t.context "config fileが存在しforceがfalseの場合"; {
    z.t.it "falseを返す"; {
      local config_file=/tmp/z_t/wtproxy_init_config_existing/sample.env
      z.dir.make path=${config_file:h}
      z.file.write path=$config_file content=exists
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return $config_file"
      z.t.mock name="z.io.error"

      z.wtproxy.init._config.file

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "$config_file already exists"
    }
  }

  z.t.context "config fileが存在しforceがtrueの場合"; {
    z.t.it "config fileを上書きする"; {
      local config_file=/tmp/z_t/wtproxy_init_config_force/sample.env
      z.dir.make path=${config_file:h}
      z.file.write path=$config_file content=exists
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return $config_file"
      z.t.mock name="z.wtproxy.init._config.content" behavior="z.return 'Z_WTPROXY_PROXY_PORT_1=3100'"

      local result=$(z.wtproxy.init._config.file force=true)
      local content=$(cat $config_file)

      z.t.expect "$result" "created: $config_file"
      z.t.expect "$content" "Z_WTPROXY_PROXY_PORT_1=3100"
    }
  }

  z.t.context "config file pathが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return"
      z.t.mock name="z.io.error"

      z.wtproxy.init._config.file

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "git worktree root is required"
    }
  }
}
