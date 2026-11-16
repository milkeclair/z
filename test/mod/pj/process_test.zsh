source ${z_main}

z.t.describe "z.pj"; {
  z.t.context "登録先に空白がある場合"; {
    z.t.it "空白入りの登録先をcodeの一引数に渡しcwdを変えない"; {
      local fixture_root="/tmp/z_t/pj_process_open_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/open"
      local directory="$fixture_root/project with spaces"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.dir.make path="$directory"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$directory"$'\n'
      z.t.mock name="code"
      local before_dir=$PWD

      z.pj example

      z.t.mock.result name="code"
      z.t.expect.reply.is.arr "$directory"
      z.t.expect "$PWD" "$before_dir"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "codeが失敗する場合"; {
    z.t.it "codeの失敗statusを返す"; {
      local fixture_root="/tmp/z_t/pj_process_open_failed_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/open_failed"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$fixture_root"$'\n'
      z.t.mock name=code behavior='return 23'

      z.pj example

      z.t.expect.status 23

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "引数の個数が不正な場合"; {
    z.t.it "引数不足・過剰はusage付きで失敗する"; {
      z.t.mock name="z.io.error"

      z.pj # zls: ignore

      z.t.expect.status.is.false skip_unmock=true
      z.t.mock.result name="z.io.error"
      z.t.expect.reply "Usage: z.pj <name>" skip_unmock=true

      z.pj one two

      z.t.expect.status.is.false
    }
  }

  z.t.context "登録先が移動済みの場合"; {
    z.t.it "移動済みのdirectoryを開かない"; {
      local fixture_root="/tmp/z_t/pj_process_stale_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/stale"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$fixture_root/not-there"$'\n'
      z.t.mock name=z.io.error
      z.t.mock name=code

      z.pj example
      local result_code=$?
      z.t.mock.result name=code
      local called=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$called" ""

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "codeが利用できない場合"; {
    z.t.it "codeが見つからない場合は失敗する"; {
      local fixture_root="/tmp/z_t/pj_process_no_code_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/no_code"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$fixture_root"$'\n'
      z.t.mock name=whence behavior='return 1'
      z.t.mock name=z.io.error

      z.pj example

      z.t.expect.status.is.false

      z.dir.remove path="$fixture_root"
    }
  }
}

z.t.describe "z.pj.add"; {
  z.t.context "有効な名前とdirectoryを指定した場合"; {
    z.t.it "登録先を絶対パスで永続化する"; {
      local fixture_root="/tmp/z_t/pj_process_add_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/add"
      z.dir.make path="$fixture_root/project"

      z.pj.add name=example dir="$fixture_root/project/.." > "$fixture_root/added"
      local result_code=$?
      z.file.read path="$fixture_root/added" && local output=$REPLY
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example"
      local saved=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$saved" "$fixture_root"
      z.t.expect.includes "$output" Registered:

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録先に特殊文字を含む場合"; {
    z.t.it "バックスラッシュやシェル構文を保存・表示時に評価しない"; {
      local fixture_root="/tmp/z_t/pj_process_literal_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/literal"
      local directory="$fixture_root/"'project\literal $value; touch marker'
      z.dir.make path="$directory"

      z.pj.add name=literal dir="$directory" > "$fixture_root/literal_output"
      local result_code=$?
      z.file.read path="$XDG_CONFIG_HOME/z/pj/literal" && local saved=$REPLY
      z.file.read path="$fixture_root/literal_output" && local output=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$saved" "$directory"
      z.t.expect "$output" "Registered: literal -> $directory"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "変換されやすい文字列を名前に指定した場合"; {
    z.t.it "true・false・null・voidという名前をそのまま登録する"; {
      local fixture_root="/tmp/z_t/pj_process_literal_names_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/literal_names"
      local name
      for name in true false null void; do
        z.pj.add name="$name" dir="$fixture_root" >/dev/null 2>&1
        local result_code=$?
        z.file.exists "$XDG_CONFIG_HOME/z/pj/$name"
        local registered=$?

        z.t.expect "$result_code" 0
        z.t.expect "$registered" 0
      done
      z.file.not.exists "$XDG_CONFIG_HOME/z/pj/0" && z.file.not.exists "$XDG_CONFIG_HOME/z/pj/1"

      z.t.expect.status.is.true

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "相対directory名がfalseの場合"; {
    z.t.it "falseという相対directory名を別の値へ変換しない"; {
      local fixture_root="/tmp/z_t/pj_process_literal_directory_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/literal_directory"
      z.dir.make path="$fixture_root/false"
      (cd "$fixture_root" && z.pj.add name=example dir=false) >/dev/null 2>&1
      local result_code=$?
      z.file.exists "$XDG_CONFIG_HOME/z/pj/example"
      local registered=$?

      z.t.expect "$result_code" 0
      z.t.expect "$registered" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "同じ名前が登録済みの場合"; {
    z.t.it "同名の登録を上書きしない"; {
      local fixture_root="/tmp/z_t/pj_process_duplicate_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/duplicate"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'
      z.t.mock name=z.io.error

      z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1
      local result_code=$?
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example"
      local saved=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$saved" /tmp

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録先がdirectoryではない場合"; {
    z.t.it "存在しないdirectory・通常ファイルを登録しない"; {
      local fixture_root="/tmp/z_t/pj_process_non_directory_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/non_directory"
      z.file.make path="$fixture_root/plain_file"
      z.t.mock name=z.io.error

      z.pj.add name=missing dir="$fixture_root/not-there"

      z.t.expect.status.is.false skip_unmock=true
      z.pj.add name=file dir="$fixture_root/plain_file"

      z.t.expect.status.is.false
      z.dir.not.exists "$XDG_CONFIG_HOME"

      z.t.expect.status.is.true

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "必要な引数がない場合"; {
    z.t.it "名前やdirの不足を拒否する"; {
      local fixture_root="/tmp/z_t/pj_process_missing_args_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/missing_args"
      z.t.mock name=z.io.error

      z.pj.add dir="$fixture_root" # zls: ignore missing-named-argument

      z.t.expect.status.is.false skip_unmock=true
      z.pj.add name=example # zls: ignore missing-named-argument

      z.t.expect.status.is.false skip_unmock=true
      z.pj.add name=../outside dir="$fixture_root"

      z.t.expect.status.is.false
      z.dir.not.exists "$XDG_CONFIG_HOME"

      z.t.expect.status.is.true

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "tildeまたは相対パスを指定した場合"; {
    z.t.it "tildeと相対パスを正規化する"; {
      local fixture_root="/tmp/z_t/pj_process_normalize_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/normalize"

      z.pj.add name=home dir='~/' >/dev/null
      z.file.read path="$XDG_CONFIG_HOME/z/pj/home" && local saved_home=$REPLY

      z.pj.add name=current dir=. >/dev/null
      z.file.read path="$XDG_CONFIG_HOME/z/pj/current" && local saved_current=$REPLY

      z.t.expect "$saved_home" "$HOME"
      z.t.expect "$saved_current" "$PWD"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録先に改行がある場合"; {
    z.t.it "改行を含むパスを拒否する"; {
      local fixture_root="/tmp/z_t/pj_process_newline_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/newline"
      local directory="$fixture_root/"$'line\nbreak'
      z.dir.make path="$directory"
      z.t.mock name=z.io.error

      z.pj.add name=example dir="$directory"

      z.t.expect.status.is.false
      z.dir.not.exists "$XDG_CONFIG_HOME"

      z.t.expect.status.is.true

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "設定directoryを作れない場合"; {
    z.t.it "設定保存先を作れない場合は失敗する"; {
      local fixture_root="/tmp/z_t/pj_process_blocked_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/blocked"
      z.file.write path="$XDG_CONFIG_HOME" content=blocked$'\n'

      z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1

      z.t.expect.status.is.false

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録の書き込みに失敗する場合"; {
    z.t.it "登録ファイルを書き込めない場合は成功を報告しない"; {
      local fixture_root="/tmp/z_t/pj_process_write_failure_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/write_failure"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      chmod 500 "$XDG_CONFIG_HOME/z/pj"

      z.pj.add name=example dir="$fixture_root" > "$fixture_root/write_failure_output" 2>/dev/null
      local result_code=$?
      z.file.read path="$fixture_root/write_failure_output" && local output=$REPLY
      chmod 700 "$XDG_CONFIG_HOME/z/pj"
      z.file.not.exists "$XDG_CONFIG_HOME/z/pj/example"
      local unchanged=$?

      z.t.expect "$result_code" 1
      z.t.expect "$output" ""
      z.t.expect "$unchanged" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録先がsymlinkの場合"; {
    z.t.it "directoryのsymlinkを実体の絶対パスで登録する"; {
      local fixture_root="/tmp/z_t/pj_process_real_directory_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/real_directory"
      z.dir.make path="$fixture_root/real_project"
      ln -s "$fixture_root/real_project" "$fixture_root/project_link"

      z.pj.add name=example dir="$fixture_root/project_link" >/dev/null
      local result_code=$?
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example" && local saved=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$saved" "$fixture_root/real_project"

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録ファイルがsymlinkの場合"; {
    z.t.it "symlinkの登録を上書きしない"; {
      local fixture_root="/tmp/z_t/pj_process_add_symlink_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/add_symlink"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$fixture_root/target" content=preserved$'\n'
      ln -s "$fixture_root/target" "$XDG_CONFIG_HOME/z/pj/example"

      z.pj.add name=example dir="$fixture_root" >/dev/null 2>&1
      local result_code=$?
      z.file.read path="$fixture_root/target"
      local saved=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$saved" preserved

      z.dir.remove path="$fixture_root"
    }
  }
}

z.t.describe "z.pj.list"; {
  z.t.context "複数のプロジェクトが登録済みの場合"; {
    z.t.it "名前順で名前と登録先を表示する"; {
      local fixture_root="/tmp/z_t/pj_process_list_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/list"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/zeta" content=/tmp/zeta$'\n'
      z.file.write path="$XDG_CONFIG_HOME/z/pj/alpha" content='/tmp/alpha space'$'\n'
      local output=$(z.pj.list)

      z.t.expect "$output" $'alpha\t/tmp/alpha space\nzeta\t/tmp/zeta'

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録がない場合"; {
    z.t.it "未登録でも保存先を作らず案内を表示する"; {
      local fixture_root="/tmp/z_t/pj_process_empty_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/empty"
      local output=$(z.pj.list)

      z.t.expect "$output" 'No projects registered.'
      z.dir.not.exists "$XDG_CONFIG_HOME"

      z.t.expect.status.is.true

      z.dir.remove path="$fixture_root"
    }
  }
}

z.t.describe "z.pj.remove"; {
  z.t.context "登録名を指定した場合"; {
    z.t.it "指定した登録だけを削除しproject directoryを残す"; {
      local fixture_root="/tmp/z_t/pj_process_remove_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/remove"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.dir.make path="$fixture_root/keep_project"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content="$fixture_root/keep_project"$'\n'
      z.file.write path="$XDG_CONFIG_HOME/z/pj/other" content=/tmp$'\n'

      z.pj.remove example >/dev/null
      local result_code=$?
      z.file.not.exists "$XDG_CONFIG_HOME/z/pj/example" &&
      z.file.exists "$XDG_CONFIG_HOME/z/pj/other" &&
      z.dir.exists "$fixture_root/keep_project"
      local preserved=$?

      z.t.expect "$result_code" 0
      z.t.expect "$preserved" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "登録を削除できない場合"; {
    z.t.it "登録ファイルを削除できない場合は既存データを残して失敗する"; {
      local fixture_root="/tmp/z_t/pj_process_remove_failure_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/remove_failure"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'
      chmod 500 "$XDG_CONFIG_HOME/z/pj"

      z.pj.remove example > "$fixture_root/remove_failure_output" 2>/dev/null
      local result_code=$?
      z.file.read path="$fixture_root/remove_failure_output" && local output=$REPLY
      chmod 700 "$XDG_CONFIG_HOME/z/pj"
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example" && local saved=$REPLY

      z.t.expect "$result_code" 1
      z.t.expect "$output" ""
      z.t.expect "$saved" /tmp

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "引数が不正な場合"; {
    z.t.it "空名や過剰な引数で登録を削除しない"; {
      local fixture_root="/tmp/z_t/pj_process_remove_arguments_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/remove_arguments"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'

      z.pj.remove '' >/dev/null 2>&1
      local empty_code=$?

      z.pj.remove example extra >/dev/null 2>&1
      local extra_code=$?
      z.file.exists "$XDG_CONFIG_HOME/z/pj/example"
      local preserved=$?

      z.t.expect "$empty_code" 1
      z.t.expect "$extra_code" 1
      z.t.expect "$preserved" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "指定した登録がない場合"; {
    z.t.it "登録がなければ失敗する"; {
      local fixture_root="/tmp/z_t/pj_process_remove_missing_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/remove_missing"
      z.t.mock name=z.io.error

      z.pj.remove missing

      z.t.expect.status.is.false

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "引数なしで番号を選んだ場合"; {
    z.t.it "引数なしでは番号で選んだ登録だけを削除する"; {
      local fixture_root="/tmp/z_t/pj_process_select_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/select"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/alpha" content=/tmp$'\n'
      z.file.write path="$XDG_CONFIG_HOME/z/pj/zeta" content=/tmp$'\n'

      z.pj.remove <<< '2' >/dev/null 2>&1
      local result_code=$?
      z.file.exists "$XDG_CONFIG_HOME/z/pj/alpha" && z.file.not.exists "$XDG_CONFIG_HOME/z/pj/zeta"
      local preserved=$?

      z.t.expect "$result_code" 0
      z.t.expect "$preserved" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "選択をキャンセルした場合"; {
    z.t.it "入力をキャンセルした場合は登録を維持する"; {
      local fixture_root="/tmp/z_t/pj_process_cancel_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/cancel"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'

      z.pj.remove <<< '' >/dev/null 2>&1
      local blank_code=$?

      z.pj.remove </dev/null >/dev/null 2>&1
      local eof_code=$?
      z.file.exists "$XDG_CONFIG_HOME/z/pj/example"
      local preserved=$?

      z.t.expect "$blank_code" 0
      z.t.expect "$eof_code" 0
      z.t.expect "$preserved" 0

      z.dir.remove path="$fixture_root"
    }
  }

  z.t.context "番号や登録名が範囲外の場合"; {
    z.t.it "不正な番号やパス指定で登録を消さない"; {
      local fixture_root="/tmp/z_t/pj_process_invalid_remove_$$"
      z.dir.make path="$fixture_root"
      local XDG_CONFIG_HOME="$fixture_root/invalid_remove"
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=/tmp$'\n'

      z.pj.remove <<< '1+1' >/dev/null 2>&1
      local selection_code=$?

      z.pj.remove ../example >/dev/null 2>&1
      local name_code=$?
      z.file.exists "$XDG_CONFIG_HOME/z/pj/example"
      local preserved=$?

      z.t.expect "$selection_code" 1
      z.t.expect "$name_code" 1
      z.t.expect "$preserved" 0

      z.dir.remove path="$fixture_root"
    }
  }
}
