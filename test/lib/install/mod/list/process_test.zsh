source "$z_main"

z.t.describe "z.install.mod.list._fetch"; {
  z.t.context "配布archiveを取得できる場合"; {
    z.t.it "指定branchを一度取得してmod配布元を返す"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/z-topic/mod/example"
      z.dir.make path="$fixture/work"
      z.file.write path="$fixture/input/z-topic/mod/example/value" content=remote
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" z-topic

      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod.list._fetch dir="$fixture/work" branch=topic/change
      local result_code=$?
      local source_dir=$REPLY

      z.t.mock.result name=curl
      local call=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$source_dir" "$fixture/work/z-topic/mod"
      z.t.expect "$call" "-fLsS https://github.com/milkeclair/z/archive/refs/heads/topic/change.tar.gz -o $fixture/work/source.tar.gz"

      z.file.read path="$source_dir/example/value"
      z.t.expect.reply remote

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "取得に失敗した場合"; {
    z.t.it "展開を行わず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      local -a extracted=()
      z.t.mock name=curl behavior="return 22"
      z.t.mock name=tar behavior='extracted+=(called); return 0'

      z.install.mod.list._fetch dir="$fixture" 2>/dev/null
      local result_code=$?

      z.t.expect "$result_code" 1 skip_unmock=true
      z.t.expect "$extracted" ""

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "archiveが壊れている場合"; {
    z.t.it "失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.t.mock name=curl behavior="z.file.write path=\"$fixture/source.tar.gz\" content=invalid"

      z.install.mod.list._fetch dir="$fixture" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "mod directoryが含まれない場合"; {
    z.t.it "一覧を空として扱わず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/z-main/lib"
      z.dir.make path="$fixture/work"
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" z-main
      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod.list._fetch dir="$fixture/work" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }

  z.t.context "配布元directoryが複数ある場合"; {
    z.t.it "任意の配布元を選ばず失敗する"; {
      local fixture=$(mktemp -d /tmp/z_mod_fetch.XXXXXX)
      z.dir.make path="$fixture/input/one/mod"
      z.dir.make path="$fixture/input/two/mod"
      z.dir.make path="$fixture/work"
      tar -czf "$fixture/archive.tar.gz" -C "$fixture/input" one two
      z.t.mock name=curl behavior="cp \"$fixture/archive.tar.gz\" \"$fixture/work/source.tar.gz\""

      z.install.mod.list._fetch dir="$fixture/work" 2>/dev/null

      z.t.expect.status.is.false

      z.dir.remove path="$fixture"
    }
  }
}
