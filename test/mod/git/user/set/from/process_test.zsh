source ${z_main}

z.t.describe "z.git.user.set.from.global"; {
  z.t.context "globalの名前とメールが設定されている場合"; {
    z.t.it "localを更新してglobalと他の設定を保持する"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        git init -q "$fixture_root/repo"
        cd "$fixture_root/repo"
        git config --global user.name "Global User Name"
        git config --global user.email global@example.test
        git config --local user.name "Local User"
        git config --local user.email local@example.test
        git config --local test.unrelated kept

        z.git.user.set.from.global >/dev/null
        z.status
        local import_status=$REPLY

        print -r -- "status=$import_status"
        git config --local user.name
        git config --local user.email
        git config --local test.unrelated
        git config --global user.name
        git config --global user.email
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" $'status=0\nGlobal User Name\nglobal@example.test\nkept\nGlobal User Name\nglobal@example.test'
    }
  }

  z.t.context "globalの名前が未設定の場合"; {
    z.t.it "失敗を返してlocalの名前とメールを保持する"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        git init -q "$fixture_root/repo"
        cd "$fixture_root/repo"
        git config --global user.email global@example.test
        git config --local user.name "Local User"
        git config --local user.email local@example.test

        z.git.user.set.from.global >/dev/null
        z.status
        local import_status=$REPLY

        print -r -- "status=$import_status"
        git config --local user.name
        git config --local user.email
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" $'status=1\nLocal User\nlocal@example.test'
    }
  }

  z.t.context "globalのメールが未設定の場合"; {
    z.t.it "失敗を返してlocalの名前とメールを保持する"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        git init -q "$fixture_root/repo"
        cd "$fixture_root/repo"
        git config --global user.name "Global User Name"
        git config --local user.name "Local User"
        git config --local user.email local@example.test

        z.git.user.set.from.global >/dev/null
        z.status
        local import_status=$REPLY

        print -r -- "status=$import_status"
        git config --local user.name
        git config --local user.email
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" $'status=1\nLocal User\nlocal@example.test'
    }
  }

  z.t.context "globalの名前が空の場合"; {
    z.t.it "失敗を返してlocalの名前とメールを保持する"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        git init -q "$fixture_root/repo"
        cd "$fixture_root/repo"
        git config --global user.name ""
        git config --global user.email global@example.test
        git config --local user.name "Local User"
        git config --local user.email local@example.test

        z.git.user.set.from.global >/dev/null
        z.status
        local import_status=$REPLY

        print -r -- "status=$import_status"
        git config --local user.name
        git config --local user.email
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" $'status=1\nLocal User\nlocal@example.test'
    }
  }

  z.t.context "リポジトリの外から呼び出した場合"; {
    z.t.it "local設定を書き込めないため失敗を返す"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        cd "$fixture_root"
        git config --global user.name "Global User Name"
        git config --global user.email global@example.test

        z.git.user.set.from.global >/dev/null 2>&1
        z.status
        print -r -- "$REPLY"
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" 1
    }
  }

  z.t.context "local設定ファイルがロックされている場合"; {
    z.t.it "失敗を返してlocal設定を保持する"; {
      local fixture_root=$(mktemp -d)
      local actual=$(
        export GIT_CONFIG_GLOBAL=$fixture_root/global.config GIT_CONFIG_NOSYSTEM=1
        git init -q "$fixture_root/repo"
        cd "$fixture_root/repo"
        git config --global user.name "Global User Name"
        git config --global user.email global@example.test
        git config --local user.name "Local User"
        git config --local user.email local@example.test
        z.file.write path=.git/config.lock content=""

        z.git.user.set.from.global >/dev/null 2>&1
        z.status
        local import_status=$REPLY

        print -r -- "status=$import_status"
        git config --local user.name
        git config --local user.email
      )
      z.dir.remove path=$fixture_root

      z.t.expect "$actual" $'status=1\nLocal User\nlocal@example.test'
    }
  }
}
