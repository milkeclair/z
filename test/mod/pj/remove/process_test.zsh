source ${z_main}

z.t.describe "z.pj.remove._menu"; {
  z.t.context "候補名がある場合"; {
    z.t.it "標準エラーへ番号順に表示する"; {
      local output=$(z.pj.remove._menu alpha zeta 2>&1)

      z.t.expect "$output" $'1) alpha\n2) zeta'
    }
  }
}

z.t.describe "z.pj.remove._select"; {
  z.t.context "候補の番号が入力された場合"; {
    z.t.it "名前順の番号に対応する名前を返す"; {
      local fixture_root="/tmp/z_t/pj_select_selected_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/selected"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/alpha"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/zeta"

      z.pj.remove._select <<< '2' 2>/dev/null
      local result_code=$?
      local selected=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$selected" zeta

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録がない場合"; {
    z.t.it "未登録の場合は入力を求めず空で成功する"; {
      local fixture_root="/tmp/z_t/pj_select_empty_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/empty"

      z.pj.remove._select </dev/null 2>/dev/null
      local result_code=$?
      local selected=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$selected" ""

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "候補外の番号が入力された場合"; {
    z.t.it "候補外の番号は失敗し登録を変えない"; {
      local fixture_root="/tmp/z_t/pj_select_out_of_range_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/out_of_range"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.make path="$XDG_CONFIG_HOME/z/pj/example"

      z.pj.remove._select <<< 999999999999999999999999999 2>/dev/null
      local result_code=$?
      local selected=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$selected" ""

      z.dir.remove path="$fixture_root"
    }
  }
}

z.t.describe "z.pj.remove._entry"; {
  z.t.context "登録済みの名前の場合"; {
    z.t.it "登録だけを削除しdirectoryを残す"; {
      local XDG_CONFIG_HOME=/tmp/z_t/pj_remove_entry
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write.literal path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp

      z.pj.remove._entry example

      z.t.expect.status.is.true
      z.file.not.exists "$XDG_CONFIG_HOME/z/pj/example"

      z.t.expect.status.is.true
      z.dir.exists /tmp

      z.t.expect.status.is.true
    }
  }
}
