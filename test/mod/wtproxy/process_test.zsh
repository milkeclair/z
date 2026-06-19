source ${z_main}

z.t.describe "z.wtproxy"; {
  z.t.context "呼び出した場合"; {
    z.t.it "statusを呼び出す"; {
      z.t.mock name="z.wtproxy.status" behavior="z.return called"

      z.wtproxy

      z.t.expect.reply called
    }
  }
}

z.t.describe "z.wtproxy.help"; {
  z.t.context "呼び出した場合"; {
    z.t.it "使い方を表示する"; {
      local result=$(z.wtproxy.help)

      z.t.expect.includes "$result" "init:    z.wtproxy.init ?proxy_port_N=<port> ?force=true"
      z.t.expect.includes "$result" "env:     z.wtproxy.env ?command..."
      z.t.expect.includes "$result" "z.wtproxy.env docker compose up"
    }
  }
}

z.t.describe "z.wtproxy.init"; {
  z.t.context "引数を指定した場合"; {
    z.t.it "init.config.fileに引数を渡す"; {
      z.t.mock name="z.wtproxy.init._config.file"

      z.wtproxy.init proxy_port_1=3000 force=true

      z.t.mock.result name="z.wtproxy.init._config.file"
      z.t.expect.reply.is.arr proxy_port_1=3000 force=true
    }
  }
}

z.t.describe "z.wtproxy.env"; {
  z.t.context "commandが渡されない場合"; {
    z.t.it "worktree用のenvを出力する"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(compose_project_name project_feat worktree_port_1 3001)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"

      local result=$(z.wtproxy.env)

      z.t.expect "$result" $'COMPOSE_PROJECT_NAME=project_feat\nZ_WTPROXY_WORKTREE_PORT_1=3001'
    }
  }

  z.t.context "commandが渡された場合"; {
    z.t.it "worktree用のenvを付けてcommandを実行する"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(compose_project_name project_feat worktree_port_1 3001)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"

      local result=$(z.wtproxy.env zsh -f -c 'print -r -- "$COMPOSE_PROJECT_NAME:$Z_WTPROXY_WORKTREE_PORT_1"')

      z.t.expect "$result" "project_feat:3001"
    }
  }

  z.t.context "commandがshell functionの場合"; {
    z.t.it "worktree用のenvを付けてfunctionを実行する"; {
      z.t.mock name="z.wtproxy._entry.current" behavior="
        local -A entry=(compose_project_name project_feat worktree_port_1 3001)
        z.return.hash entry
      "
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"
      wtproxy_test_dev() {
        print -r -- "$COMPOSE_PROJECT_NAME:$Z_WTPROXY_WORKTREE_PORT_1:$*"
      }

      local result=$(z.wtproxy.env wtproxy_test_dev back)

      z.t.expect "$result" "project_feat:3001:back"
      unfunction wtproxy_test_dev
    }
  }

  z.t.context "current entryが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior="return 1"

      z.wtproxy.env

      z.t.expect.status.is.false
    }
  }

  z.t.context "port keyが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(compose_project_name project_feat)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._port.keys" behavior="return 1"

      z.wtproxy.env

      z.t.expect.status.is.false
    }
  }

  z.t.context "commandが失敗した場合"; {
    z.t.it "commandのstatusを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(compose_project_name project_feat worktree_port_1 3001)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._port.keys" behavior="z.return worktree_port_1"

      z.wtproxy.env zsh -f -c 'exit 7'

      z.t.expect.status 7
    }
  }
}

z.t.describe "z.wtproxy.use"; {
  z.t.context "current entryが取得できる場合"; {
    z.t.it "entryを出力する"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._print.entry"

      z.wtproxy.use

      z.t.mock.result name="z.wtproxy._entry.current"
      z.t.expect.reply "activate=true" skip_unmock=true
      z.t.mock.result name="z.wtproxy._print.entry"
      z.t.expect.reply.is.arr path /tmp/worktree
    }
  }

  z.t.context "current entryが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior="return 1"

      z.wtproxy.use

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.wtproxy.start"; {
  z.t.context "daemonを開始できる場合"; {
    z.t.it "entryを出力する"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy.start._daemon" behavior="return 0"
      z.t.mock name="z.wtproxy._print.entry"

      z.wtproxy.start

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="z.wtproxy._print.entry"
      z.t.expect.reply.is.arr path /tmp/worktree
    }
  }

  z.t.context "current entryが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior="return 1"

      z.wtproxy.start

      z.t.expect.status.is.false
    }
  }

  z.t.context "daemonを開始できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy._entry.current" behavior='
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy.start._daemon" behavior="return 1"

      z.wtproxy.start

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.wtproxy.stop"; {
  z.t.context "daemonを停止できる場合"; {
    z.t.it "stoppedを出力する"; {
      z.t.mock name="z.wtproxy.stop._daemon" behavior="return 0"

      local result=$(z.wtproxy.stop)

      z.t.expect "$result" stopped
    }
  }

  z.t.context "daemonを停止できない場合"; {
    z.t.it "not runningを出力する"; {
      z.t.mock name="z.wtproxy.stop._daemon" behavior="return 1"

      local result=$(z.wtproxy.stop)

      z.t.expect "$result" "not running"
    }
  }
}

z.t.describe "z.wtproxy.rm"; {
  z.t.context "current entryが存在する場合"; {
    z.t.it "Docker resourceを削除してentry削除結果を出力する"; {
      z.t.mock name="z.wtproxy.rm._current.entry" behavior='
        local -A entry=(compose_project_name project_feat)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._docker.prune" behavior='
        z.is.eq "$1" project_feat
      '
      z.t.mock name="z.wtproxy.rm._current" behavior='
        z.is.eq "$1" expected_project=project_feat || return 1
        local -A result=(removed_path /tmp/worktree entries_count 1 removed_project project_feat)
        z.return.hash result
      '

      local result=$(z.wtproxy.rm)

      z.t.expect.includes "$result" "removed: /tmp/worktree"
      z.t.expect.includes "$result" "entries: 1"
      z.t.expect.includes "$result" "docker_resource_project: project_feat"
    }
  }

  z.t.context "current entryが取得できない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy.rm._current.entry" behavior="return 1"

      z.wtproxy.rm

      z.t.expect.status.is.false
    }
  }

  z.t.context "Docker resource削除に失敗した場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy.rm._current.entry" behavior='
        local -A entry=(compose_project_name project_feat)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 1"

      z.wtproxy.rm

      z.t.expect.status.is.false
    }
  }

  z.t.context "compose projectが空の場合"; {
    z.t.it "Docker resourceを削除せずentry削除結果を出力する"; {
      z.t.mock name="z.wtproxy.rm._current.entry" behavior='
        local -A entry=()
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 1"
      z.t.mock name="z.wtproxy.rm._current" behavior='
        z.is.eq "$1" expected_project= || return 1
        local -A result=(removed_path /tmp/worktree entries_count 0)
        z.return.hash result
      '

      local result=$(z.wtproxy.rm)

      z.t.expect.includes "$result" "removed: /tmp/worktree"
      z.t.expect.includes "$result" "entries: 0"
      z.t.expect.excludes "$result" "docker_resource_project:"
    }
  }
}

z.t.describe "z.wtproxy.prune"; {
  z.t.context "stale entryがある場合"; {
    z.t.it "Docker resourceを削除して結果を出力する"; {
      z.t.mock name="z.wtproxy.prune._stale" behavior='
        local -A result=(entries_count 1 pruned_projects "project_a project_b")
        z.return.hash result
      '
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 0"

      local result=$(z.wtproxy.prune)

      z.t.expect.includes "$result" "entries: 1"
      z.t.expect.includes "$result" "docker_resource_projects: project_a project_b"
    }
  }

  z.t.context "stale entryがない場合"; {
    z.t.it "Docker resourceを削除せず結果を出力する"; {
      z.t.mock name="z.wtproxy.prune._stale" behavior='
        local -A result=(entries_count 1)
        z.return.hash result
      '
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 1"

      local result=$(z.wtproxy.prune)

      z.t.expect.includes "$result" "entries: 1"
      z.t.expect.excludes "$result" "docker_resource_projects:"
    }
  }

  z.t.context "stale entryの取得に失敗した場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="z.wtproxy.prune._stale" behavior="return 1"

      z.wtproxy.prune

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.wtproxy.status"; {
  z.t.context "active entryがありproxyが起動している場合"; {
    z.t.it "entryとrunningを出力する"; {
      z.t.mock name="z.wtproxy._entry.active" behavior='
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      '
      z.t.mock name="z.wtproxy._print.entry" behavior="print -r -- entry"
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 0"

      local result=$(z.wtproxy.status)

      z.t.expect.includes "$result" entry
      z.t.expect.includes "$result" "proxy: running"
    }
  }

  z.t.context "active entryがなくproxyが停止している場合"; {
    z.t.it "noneとstoppedを出力する"; {
      z.t.mock name="z.wtproxy._entry.active" behavior="return 1"
      z.t.mock name="z.wtproxy._proxy.is.running" behavior="return 1"

      local result=$(z.wtproxy.status)

      z.t.expect.includes "$result" "active: none"
      z.t.expect.includes "$result" "proxy: stopped"
    }
  }
}
