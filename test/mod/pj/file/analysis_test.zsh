source ${z_main}

z.t.describe "z.pj.file._root"; {
  z.t.context "XDG_CONFIG_HOMEが設定されている場合"; {
    z.t.it "XDG_CONFIG_HOMEを使う"; {
      local fixture_root="/tmp/z_t/pj_file_config_home_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/config home"

      z.pj.file._root

      z.t.expect.reply "$fixture_root/config home/z/pj"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "XDG_CONFIG_HOMEが空の場合"; {
    z.t.it "未指定ならhome配下を使う"; {
      local XDG_CONFIG_HOME=""

      z.pj.file._root

      z.t.expect.reply "$HOME/.config/z/pj"
    }
  }
}

z.t.describe "z.pj.file._path"; {
  z.t.context "有効な名前の場合"; {
    z.t.it "有効な名前の保存先を返す"; {
      local fixture_root="/tmp/z_t/pj_file_files_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/files"

      z.pj.file._path example

      z.t.expect.reply "$fixture_root/files/z/pj/example"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "名前が不正な場合"; {
    z.t.it "不正な名前は失敗し古いREPLYを返さない"; {
      z.t.mock name=z.io.error
      REPLY=previous

      z.pj.file._path ../outside
      local result_code=$?
      local result=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$result" ""
    }
  }
}

z.t.describe "z.pj.file._names"; {
  z.t.context "複数のファイルとdirectoryがある場合"; {
    z.t.it "名前順で通常の登録ファイルだけを返す"; {
      local fixture_root="/tmp/z_t/pj_file_names_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/names"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj/subdir"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/zeta"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/alpha"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/has space"
      ln -s "$XDG_CONFIG_HOME/z/pj/alpha" "$XDG_CONFIG_HOME/z/pj/linked"

      z.pj.file._names

      z.t.expect.reply.is.arr alpha zeta

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "保存先が存在しない場合"; {
    z.t.it "保存先が未作成なら空配列を返す"; {
      local fixture_root="/tmp/z_t/pj_file_no_names_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/no_names"

      z.pj.file._names

      z.t.expect.reply.is.null

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "名前がtrueだけの場合"; {
    z.t.it "trueという名前を別の値へ変換しない"; {
      local fixture_root="/tmp/z_t/pj_file_literal_name_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/literal_name"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/true"

      z.pj.file._names

      z.t.expect.reply.is.arr true

      z.dir.remove path="$fixture_root"
    }
  }
}

z.t.describe "z.pj.file._directory"; {
  z.t.context "保存されたパスに特殊文字がある場合"; {
    z.t.it "空白やバックスラッシュを含む保存値をそのまま返す"; {
      local fixture_root="/tmp/z_t/pj_file_read_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/read"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      local directory='/tmp/project with spaces\literal $value'
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$directory"$'\n'

      z.pj.file._directory example

      z.t.expect.reply "$directory"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録がない場合"; {
    z.t.it "未登録なら失敗してREPLYを空にする"; {
      local fixture_root="/tmp/z_t/pj_file_missing_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/missing"
      z.t.mock name=z.io.error
      REPLY=previous

      z.pj.file._directory missing
      local result_code=$?
      local result=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$result" ""

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録データが破損している場合"; {
    z.t.it "相対パスや複数行の破損データを拒否する"; {
      local fixture_root="/tmp/z_t/pj_file_invalid_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/invalid"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/relative" content=relative$'\n'
      z.file.write path="$XDG_CONFIG_HOME/z/pj/multiple" content=$'/tmp/one\n/tmp/two'$'\n'
      z.t.mock name=z.io.error

      z.pj.file._directory relative

      z.t.expect.status.is.false skip_unmock=true
      z.pj.file._directory multiple

      z.t.expect.status.is.false

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "読み取り権限がない場合"; {
    z.t.it "登録を読めない場合は失敗してREPLYを空にする"; {
      local fixture_root="/tmp/z_t/pj_file_unreadable_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/unreadable"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'
      chmod 000 "$XDG_CONFIG_HOME/z/pj/example"

      z.pj.file._directory example 2>/dev/null
      local result_code=$?
      local result=$REPLY
      chmod 600 "$XDG_CONFIG_HOME/z/pj/example"

      z.t.expect "$result_code" 1
      z.t.expect "$result" ""

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録がsymlinkの場合"; {
    z.t.it "登録ファイルのsymlinkを読まない"; {
      local fixture_root="/tmp/z_t/pj_file_symlink_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/symlink"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$fixture_root/outside" content=/tmp$'\n'
      ln -s "$fixture_root/outside" "$XDG_CONFIG_HOME/z/pj/example"
      z.t.mock name=z.io.error

      z.pj.file._directory example

      z.t.expect.status.is.false

      z.dir.remove path="$fixture_root"
    }
  }
}
