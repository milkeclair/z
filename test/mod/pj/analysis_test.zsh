source ${z_main}
local fixture_root="/tmp/z_t/pj_analysis_$$"

z.t.describe "z.pj._root"; {
  z.t.it "XDG_CONFIG_HOMEを使う"; {
    local XDG_CONFIG_HOME="$fixture_root/config home"
    z.pj._root
    z.t.expect.reply "$fixture_root/config home/z/pj"
  }
  z.t.it "未指定ならhome配下を使う"; {
    local XDG_CONFIG_HOME=""
    z.pj._root
    z.t.expect.reply "$HOME/.config/z/pj"
  }
}

z.t.describe "z.pj._file"; {
  z.t.it "有効な名前の保存先を返す"; {
    local XDG_CONFIG_HOME="$fixture_root/files"
    z.pj._file example
    z.t.expect.reply "$fixture_root/files/z/pj/example"
  }
  z.t.it "不正な名前は失敗し古いREPLYを返さない"; {
    z.t.mock name=z.io.error
    REPLY=previous
    z.pj._file ../outside
    local result_code=$?
    local result=$REPLY
    z.t.expect "$result_code" 1
    z.t.expect "$result" ""
  }
}

z.t.describe "z.pj._names"; {
  z.t.it "名前順で通常の登録ファイルだけを返す"; {
    local XDG_CONFIG_HOME="$fixture_root/names"
    mkdir -p "$XDG_CONFIG_HOME/z/pj/subdir"
    touch "$XDG_CONFIG_HOME/z/pj/zeta" "$XDG_CONFIG_HOME/z/pj/alpha" "$XDG_CONFIG_HOME/z/pj/has space"
    ln -s "$XDG_CONFIG_HOME/z/pj/alpha" "$XDG_CONFIG_HOME/z/pj/linked"
    z.pj._names
    z.t.expect.reply.is.arr alpha zeta
  }
  z.t.it "保存先が未作成なら空配列を返す"; {
    local XDG_CONFIG_HOME="$fixture_root/no_names"
    z.pj._names
    z.t.expect.reply.is.null
  }
  z.t.it "trueという名前を別の値へ変換しない"; {
    local XDG_CONFIG_HOME="$fixture_root/literal_name"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    touch "$XDG_CONFIG_HOME/z/pj/true"
    z.pj._names
    z.t.expect "${REPLY[1]}" true
  }
}

z.t.describe "z.pj._directory"; {
  z.t.it "空白やバックスラッシュを含む保存値をそのまま返す"; {
    local XDG_CONFIG_HOME="$fixture_root/read"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    local directory='/tmp/project with spaces\literal $value'
    print -r -- "$directory" > "$XDG_CONFIG_HOME/z/pj/example"
    z.pj._directory example
    z.t.expect.reply "$directory"
  }
  z.t.it "未登録なら失敗してREPLYを空にする"; {
    local XDG_CONFIG_HOME="$fixture_root/missing"
    z.t.mock name=z.io.error
    REPLY=previous
    z.pj._directory missing
    local result_code=$?
    local result=$REPLY
    z.t.expect "$result_code" 1
    z.t.expect "$result" ""
  }
  z.t.it "相対パスや複数行の破損データを拒否する"; {
    local XDG_CONFIG_HOME="$fixture_root/invalid"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- relative > "$XDG_CONFIG_HOME/z/pj/relative"
    print -r -- $'/tmp/one\n/tmp/two' > "$XDG_CONFIG_HOME/z/pj/multiple"
    z.t.mock name=z.io.error
    z.pj._directory relative
    z.t.expect.status.is.false skip_unmock=true
    z.pj._directory multiple
    z.t.expect.status.is.false
  }
  z.t.it "登録を読めない場合は失敗してREPLYを空にする"; {
    local XDG_CONFIG_HOME="$fixture_root/unreadable"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    chmod 000 "$XDG_CONFIG_HOME/z/pj/example"
    z.pj._directory example 2>/dev/null
    local result_code=$?
    local result=$REPLY
    chmod 600 "$XDG_CONFIG_HOME/z/pj/example"
    z.t.expect "$result_code" 1
    z.t.expect "$result" ""
  }
  z.t.it "登録ファイルのsymlinkを読まない"; {
    local XDG_CONFIG_HOME="$fixture_root/symlink"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$fixture_root/outside"
    ln -s "$fixture_root/outside" "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=z.io.error
    z.pj._directory example
    z.t.expect.status.is.false
  }
}
