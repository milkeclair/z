source ${z_main}
local fixture_root="/tmp/z_t/pj_process_$$"

z.t.describe "z.pj"; {
  z.t.it "空白入りの登録先をcodeの一引数に渡しcwdを変えない"; {
    local XDG_CONFIG_HOME="$fixture_root/open"
    local directory="$fixture_root/project with spaces"
    mkdir -p "$XDG_CONFIG_HOME/z/pj" "$directory"
    print -r -- "$directory" > "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=code behavior='print -r -- "$#:$1"'
    local before_dir=$PWD
    local output=$(z.pj example)
    z.t.expect "$output" "1:$directory"
    z.t.expect "$PWD" "$before_dir"
  }
  z.t.it "codeの失敗statusを返す"; {
    local XDG_CONFIG_HOME="$fixture_root/open_failed"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- "$fixture_root" > "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=code behavior='return 23'
    z.pj example
    local result_code=$?
    z.t.expect "$result_code" 23
  }
  z.t.it "引数不足・過剰はusage付きで失敗する"; {
    mkdir -p "$fixture_root"
    z.pj > "$fixture_root/usage" 2>&1
    local result_code=$?
    local output=$(<"$fixture_root/usage")
    z.t.expect "$result_code" 1
    z.t.expect.includes "$output" 'Usage:'
    z.pj one two >/dev/null 2>&1
    z.t.expect.status.is.false
  }
  z.t.it "移動済みのdirectoryを開かない"; {
    local XDG_CONFIG_HOME="$fixture_root/stale"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- "$fixture_root/not-there" > "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=z.io.error
    z.t.mock name=code
    z.pj example
    local result_code=$?
    z.t.mock.result name=code
    local called=$REPLY
    z.t.expect "$result_code" 1
    z.t.expect "$called" ""
  }
  z.t.it "codeが見つからない場合は失敗する"; {
    local XDG_CONFIG_HOME="$fixture_root/no_code"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- "$fixture_root" > "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=whence behavior='return 1'
    z.t.mock name=z.io.error
    z.pj example
    z.t.expect.status.is.false
  }
}

z.t.describe "z.pj.add"; {
  z.t.it "登録先を絶対パスで永続化する"; {
    local XDG_CONFIG_HOME="$fixture_root/add"
    mkdir -p "$fixture_root/project"
    z.pj.add name=example dir="$fixture_root/project/.." > "$fixture_root/added"
    local result_code=$?
    local output=$(<"$fixture_root/added")
    local saved=$(cat "$XDG_CONFIG_HOME/z/pj/example")
    z.t.expect "$result_code" 0
    z.t.expect "$saved" "$fixture_root"
    z.t.expect.includes "$output" Registered:
  }
  z.t.it "バックスラッシュやシェル構文を保存・表示時に評価しない"; {
    local XDG_CONFIG_HOME="$fixture_root/literal"
    local directory="$fixture_root/"'project\literal $value; touch marker'
    mkdir -p "$directory"
    z.pj.add name=literal dir="$directory" > "$fixture_root/literal_output"
    local result_code=$?
    local saved=$(<"$XDG_CONFIG_HOME/z/pj/literal")
    local output=$(<"$fixture_root/literal_output")
    z.t.expect "$result_code" 0
    z.t.expect "$saved" "$directory"
    z.t.expect "$output" "Registered: literal -> $directory"
  }
  z.t.it "true・false・null・voidという名前をそのまま登録する"; {
    local XDG_CONFIG_HOME="$fixture_root/literal_names"
    local name
    for name in true false null void; do
      z.pj.add name="$name" dir="$fixture_root" >/dev/null 2>&1
      local result_code=$?
      [[ -f "$XDG_CONFIG_HOME/z/pj/$name" ]]
      local registered=$?
      z.t.expect "$result_code" 0
      z.t.expect "$registered" 0
    done
    [[ ! -e "$XDG_CONFIG_HOME/z/pj/0" && ! -e "$XDG_CONFIG_HOME/z/pj/1" ]]
    z.t.expect.status.is.true
  }
  z.t.it "falseという相対directory名を別の値へ変換しない"; {
    local XDG_CONFIG_HOME="$fixture_root/literal_directory"
    mkdir -p "$fixture_root/false"
    (cd "$fixture_root" && z.pj.add name=example dir=false) >/dev/null 2>&1
    local result_code=$?
    [[ -f "$XDG_CONFIG_HOME/z/pj/example" ]]
    local registered=$?
    z.t.expect "$result_code" 0
    z.t.expect "$registered" 0
  }
  z.t.it "同名の登録を上書きしない"; {
    local XDG_CONFIG_HOME="$fixture_root/duplicate"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    z.t.mock name=z.io.error
    z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1
    local result_code=$?
    local saved=$(cat "$XDG_CONFIG_HOME/z/pj/example")
    z.t.expect "$result_code" 1
    z.t.expect "$saved" /tmp
  }
  z.t.it "存在しないdirectory・通常ファイルを登録しない"; {
    local XDG_CONFIG_HOME="$fixture_root/non_directory"
    touch "$fixture_root/plain_file"
    z.t.mock name=z.io.error
    z.pj.add name=missing dir="$fixture_root/not-there"
    z.t.expect.status.is.false skip_unmock=true
    z.pj.add name=file dir="$fixture_root/plain_file"
    z.t.expect.status.is.false
    [[ ! -e "$XDG_CONFIG_HOME" ]]
    z.t.expect.status.is.true
  }
  z.t.it "名前やdirの不足を拒否する"; {
    local XDG_CONFIG_HOME="$fixture_root/missing_args"
    z.t.mock name=z.io.error
    z.pj.add dir="$fixture_root"
    z.t.expect.status.is.false skip_unmock=true
    z.pj.add name=example
    z.t.expect.status.is.false skip_unmock=true
    z.pj.add name=../outside dir="$fixture_root"
    z.t.expect.status.is.false
    [[ ! -e "$XDG_CONFIG_HOME" ]]
    z.t.expect.status.is.true
  }
  z.t.it "tildeと相対パスを正規化する"; {
    local XDG_CONFIG_HOME="$fixture_root/normalize"
    z.pj.add name=home dir='~/' >/dev/null
    local saved_home=$(cat "$XDG_CONFIG_HOME/z/pj/home")
    z.pj.add name=current dir=. >/dev/null
    local saved_current=$(cat "$XDG_CONFIG_HOME/z/pj/current")
    z.t.expect "$saved_home" "$HOME"
    z.t.expect "$saved_current" "$PWD"
  }
  z.t.it "改行を含むパスを拒否する"; {
    local XDG_CONFIG_HOME="$fixture_root/newline"
    local directory="$fixture_root/"$'line\nbreak'
    mkdir -p "$directory"
    z.t.mock name=z.io.error
    z.pj.add name=example dir="$directory"
    z.t.expect.status.is.false
    [[ ! -e "$XDG_CONFIG_HOME" ]]
    z.t.expect.status.is.true
  }
  z.t.it "設定保存先を作れない場合は失敗する"; {
    local XDG_CONFIG_HOME="$fixture_root/blocked"
    print -r -- blocked > "$XDG_CONFIG_HOME"
    z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1
    z.t.expect.status.is.false
  }
  z.t.it "登録ファイルを書き込めない場合は成功を報告しない"; {
    local XDG_CONFIG_HOME="$fixture_root/write_failure"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    chmod 500 "$XDG_CONFIG_HOME/z/pj"
    z.pj.add name=example dir="$fixture_root" > "$fixture_root/write_failure_output" 2>/dev/null
    local result_code=$?
    local output=$(<"$fixture_root/write_failure_output")
    chmod 700 "$XDG_CONFIG_HOME/z/pj"
    [[ ! -e "$XDG_CONFIG_HOME/z/pj/example" ]]
    local unchanged=$?
    z.t.expect "$result_code" 1
    z.t.expect "$output" ""
    z.t.expect "$unchanged" 0
  }
  z.t.it "directoryのsymlinkを実体の絶対パスで登録する"; {
    local XDG_CONFIG_HOME="$fixture_root/real_directory"
    mkdir -p "$fixture_root/real_project"
    ln -s "$fixture_root/real_project" "$fixture_root/project_link"
    z.pj.add name=example dir="$fixture_root/project_link" >/dev/null
    local result_code=$?
    local saved=$(<"$XDG_CONFIG_HOME/z/pj/example")
    z.t.expect "$result_code" 0
    z.t.expect "$saved" "$fixture_root/real_project"
  }
  z.t.it "symlinkの登録を上書きしない"; {
    local XDG_CONFIG_HOME="$fixture_root/add_symlink"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- preserved > "$fixture_root/target"
    ln -s "$fixture_root/target" "$XDG_CONFIG_HOME/z/pj/example"
    z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1
    local result_code=$?
    local saved=$(cat "$fixture_root/target")
    z.t.expect "$result_code" 1
    z.t.expect "$saved" preserved
  }
}

z.t.describe "z.pj.list"; {
  z.t.it "名前順で名前と登録先を表示する"; {
    local XDG_CONFIG_HOME="$fixture_root/list"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp/zeta > "$XDG_CONFIG_HOME/z/pj/zeta"
    print -r -- '/tmp/alpha space' > "$XDG_CONFIG_HOME/z/pj/alpha"
    local output=$(z.pj.list)
    z.t.expect "$output" $'alpha\t/tmp/alpha space\nzeta\t/tmp/zeta'
  }
  z.t.it "未登録でも保存先を作らず案内を表示する"; {
    local XDG_CONFIG_HOME="$fixture_root/empty"
    local output=$(z.pj.list)
    z.t.expect "$output" 'No projects registered.'
    [[ ! -e "$XDG_CONFIG_HOME" ]]
    z.t.expect.status.is.true
  }
}

z.t.describe "z.pj.remove"; {
  z.t.it "指定した登録だけを削除しproject directoryを残す"; {
    local XDG_CONFIG_HOME="$fixture_root/remove"
    mkdir -p "$XDG_CONFIG_HOME/z/pj" "$fixture_root/keep_project"
    print -r -- "$fixture_root/keep_project" > "$XDG_CONFIG_HOME/z/pj/example"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/other"
    z.pj.remove example >/dev/null
    local result_code=$?
    [[ ! -e "$XDG_CONFIG_HOME/z/pj/example" && -f "$XDG_CONFIG_HOME/z/pj/other" && -d "$fixture_root/keep_project" ]]
    local preserved=$?
    z.t.expect "$result_code" 0
    z.t.expect "$preserved" 0
  }
  z.t.it "登録ファイルを削除できない場合は既存データを残して失敗する"; {
    local XDG_CONFIG_HOME="$fixture_root/remove_failure"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    chmod 500 "$XDG_CONFIG_HOME/z/pj"
    z.pj.remove example > "$fixture_root/remove_failure_output" 2>/dev/null
    local result_code=$?
    local output=$(<"$fixture_root/remove_failure_output")
    chmod 700 "$XDG_CONFIG_HOME/z/pj"
    local saved=$(<"$XDG_CONFIG_HOME/z/pj/example")
    z.t.expect "$result_code" 1
    z.t.expect "$output" ""
    z.t.expect "$saved" /tmp
  }
  z.t.it "空名や過剰な引数で登録を削除しない"; {
    local XDG_CONFIG_HOME="$fixture_root/remove_arguments"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    z.pj.remove '' >/dev/null 2>&1
    local empty_code=$?
    z.pj.remove example extra >/dev/null 2>&1
    local extra_code=$?
    [[ -f "$XDG_CONFIG_HOME/z/pj/example" ]]
    local preserved=$?
    z.t.expect "$empty_code" 1
    z.t.expect "$extra_code" 1
    z.t.expect "$preserved" 0
  }
  z.t.it "登録がなければ失敗する"; {
    local XDG_CONFIG_HOME="$fixture_root/remove_missing"
    z.t.mock name=z.io.error
    z.pj.remove missing
    z.t.expect.status.is.false
  }
  z.t.it "引数なしでは番号で選んだ登録だけを削除する"; {
    local XDG_CONFIG_HOME="$fixture_root/select"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/alpha"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/zeta"
    z.pj.remove <<< '2' >/dev/null 2>&1
    local result_code=$?
    [[ -f "$XDG_CONFIG_HOME/z/pj/alpha" && ! -e "$XDG_CONFIG_HOME/z/pj/zeta" ]]
    local preserved=$?
    z.t.expect "$result_code" 0
    z.t.expect "$preserved" 0
  }
  z.t.it "入力をキャンセルした場合は登録を維持する"; {
    local XDG_CONFIG_HOME="$fixture_root/cancel"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    z.pj.remove <<< '' >/dev/null 2>&1
    local blank_code=$?
    z.pj.remove </dev/null >/dev/null 2>&1
    local eof_code=$?
    [[ -f "$XDG_CONFIG_HOME/z/pj/example" ]]
    local preserved=$?
    z.t.expect "$blank_code" 0
    z.t.expect "$eof_code" 0
    z.t.expect "$preserved" 0
  }
  z.t.it "不正な番号やパス指定で登録を消さない"; {
    local XDG_CONFIG_HOME="$fixture_root/invalid_remove"
    mkdir -p "$XDG_CONFIG_HOME/z/pj"
    print -r -- /tmp > "$XDG_CONFIG_HOME/z/pj/example"
    z.pj.remove <<< '1+1' >/dev/null 2>&1
    local selection_code=$?
    z.pj.remove ../example >/dev/null 2>&1
    local name_code=$?
    [[ -f "$XDG_CONFIG_HOME/z/pj/example" ]]
    local preserved=$?
    z.t.expect "$selection_code" 1
    z.t.expect "$name_code" 1
    z.t.expect "$preserved" 0
  }
}
