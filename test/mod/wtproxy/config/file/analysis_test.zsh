source ${z_main}

z.t.describe "z.wtproxy._config.file.path"; {
  z.t.context "default projectが取得できる場合"; {
    z.t.it "config file pathを返す"; {
      local XDG_CONFIG_HOME=/tmp/z_t/config_home
      z.t.mock name="z.wtproxy._config.file.default_project" behavior="z.return sample"

      z.wtproxy._config.file.path

      z.t.expect.reply "/tmp/z_t/config_home/wtproxy/sample.env"
    }
  }

  z.t.context "default projectが取得できない場合"; {
    z.t.it "REPLYを空にする"; {
      z.t.mock name="z.wtproxy._config.file.default_project" behavior="return 1"

      z.wtproxy._config.file.path

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.wtproxy._config.file.key"; {
  z.t.context "proxy port env名を指定した場合"; {
    z.t.it "proxy port config keyを返す"; {
      z.wtproxy._config.file.key Z_WTPROXY_PROXY_PORT_1

      z.t.expect.reply "proxy_port_1"
    }
  }

  z.t.context "未知のenv名を指定した場合"; {
    z.t.it "REPLYを空にする"; {
      z.wtproxy._config.file.key Z_WTPROXY_WORKTREE_PORT_1

      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.wtproxy._config.file.line"; {
  z.t.context "proxy port envの行を指定した場合"; {
    z.t.it "config keyと値を返す"; {
      z.wtproxy._config.file.line "Z_WTPROXY_PROXY_PORT_1=3000"

      z.t.expect.reply.is.arr proxy_port_1 3000
    }
  }

  z.t.context "export付きの行を指定した場合"; {
    z.t.it "exportを除いてconfig keyと値を返す"; {
      z.wtproxy._config.file.line "export Z_WTPROXY_PROXY_PORT_2=5432"

      z.t.expect.reply.is.arr proxy_port_2 5432
    }
  }

  z.t.context "コメント行を指定した場合"; {
    z.t.it "falseを返す"; {
      z.wtproxy._config.file.line "# Z_WTPROXY_PROXY_PORT_1=3000"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.wtproxy._config.file.values"; {
  z.t.context "config fileが存在する場合"; {
    z.t.it "既知の設定だけをhashで返す"; {
      local config_file=/tmp/z_t/wtproxy_config_values/sample.env
      z.dir.make path=${config_file:h}
      z.file.write path=$config_file content=$'Z_WTPROXY_PROXY_PORT_1=3000\nUNKNOWN=value\nexport Z_WTPROXY_PROXY_PORT_2=5432'
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return $config_file"

      z.wtproxy._config.file.values
      local -A config=("${(@)REPLY}")

      z.t.expect "$config[proxy_port_1]" 3000
      z.t.expect "$config[proxy_port_2]" 5432
      z.t.expect "$config[UNKNOWN]" ""
    }
  }

  z.t.context "config fileが存在しない場合"; {
    z.t.it "空のhashを返す"; {
      local config_file=/tmp/z_t/wtproxy_config_values_missing/sample.env
      z.file.not.exists $config_file
      z.t.expect.status.is.true
      z.t.mock name="z.wtproxy._config.file.path" behavior="z.return $config_file"

      z.wtproxy._config.file.values
      z.t.expect.status.is.true skip_unmock=true
      z.wtproxy._config.file.values
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.wtproxy._config.file.default_project"; {
  z.t.context "common git directoryが取得できる場合"; {
    z.t.it "repository root名からproject名を返す"; {
      z.t.mock name="z.git.wt.current.common_dir" behavior="z.return /repo/sample/.git"

      z.wtproxy._config.file.default_project

      z.t.expect.reply sample
    }
  }

  z.t.context "兄弟worktreeの場合"; {
    z.t.it "同じrepository root名からproject名を返す"; {
      z.t.mock name="z.git.wt.current.common_dir" behavior="z.return /repo/sample/.git"

      z.wtproxy._config.file.default_project

      z.t.expect.reply sample
    }
  }

  z.t.context "common git directoryが取得できない場合"; {
    z.t.it "失敗してREPLYを空にする"; {
      z.t.mock name="z.git.wt.current.common_dir" behavior="return 1"

      z.wtproxy._config.file.default_project
      z.t.expect.status.is.false skip_unmock=true

      z.wtproxy._config.file.default_project
      z.t.expect.reply.is.null
    }
  }
}
