source ${z_main}

z.t.describe "z.cls.capture._start"; {
  z.t.context "名前付き引数を順不同で渡す場合"; {
    z.t.it "収集するメソッド名と定義元と破棄フラグを保存する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug

      z.cls.capture._start captured_method file="test file.zsh" discard=1 stack=test_stack

      local captured_name=$z_cls_capture_method
      local captured_stack=$z_cls_capture_stack
      local captured_file=$z_cls_capture_file
      local captured_discard=$z_cls_capture_discard

      z.cls.capture._stop

      z.t.expect "$captured_name" captured_method
      z.t.expect "$captured_stack" test_stack
      z.t.expect "$captured_file" "test file.zsh"
      z.t.expect "$captured_discard" 1
    }
  }

  z.t.context "呼出元のREPLYが配列の場合"; {
    z.t.it "収集開始後も呼出元のREPLYの空要素と空白を保つ"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug
      REPLY=(before "two words" "")

      z.cls.capture._start captured_method stack=test_stack file=test_file

      local -a preserved_reply=("${REPLY[@]}")
      z.cls.capture._stop

      z.t.expect "${#preserved_reply}" 3
      z.t.expect "$preserved_reply[1]" before
      z.t.expect "$preserved_reply[2]" "two words"
      z.t.expect.is.null "$preserved_reply[3]"
    }
  }

  z.t.context "最上位の定義を収集する場合"; {
    z.t.it "最上位の空のスタックを保持する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug

      z.cls.capture._start captured_method stack= file=test_file

      local captured_stack=$z_cls_capture_stack
      z.cls.capture._stop

      z.t.expect.is.null "$captured_stack"
    }
  }

  z.t.context "discardを省略した場合"; {
    z.t.it "破棄の指定がなければメソッドを残す"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug

      z.cls.capture._start captured_method stack=test_stack file=test_file

      local captured_discard=$z_cls_capture_discard
      z.cls.capture._stop

      z.t.expect "$captured_discard" 0
    }
  }
}

z.t.describe "z.cls.capture._stop"; {
  z.t.context "元のDEBUGトラップが関数形式の場合"; {
    z.t.it "退避した関数形式のDEBUGトラップを復元する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug
      TRAPDEBUG() {
        return 0
      }

      local original_debug=$functions[TRAPDEBUG]
      z.cls.capture._start captured_method stack=test_stack file=test_file

      z.cls.capture._stop

      z.t.expect "$functions[TRAPDEBUG]" "$original_debug"

      unfunction TRAPDEBUG
    }

    z.t.it "クラスを公開した後のコマンドで元のDEBUGトラップを実行する"; {
      local -a output=()
      output=("${(@f)$(
        local -i trap_calls=0
        TRAPDEBUG() {
          (( ++trap_calls ))
          return 0
        }

        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local source_status=$?

        local calls_before=$trap_calls
        :
        local calls_after=$trap_calls

        unfunction TRAPDEBUG
        print -rl -- "$source_status" "$calls_before" "$calls_after"
      )}")

      z.t.expect "${#output}" 3
      z.t.expect "$output[1]" 0

      z.int.is.gt "$output[3]" "$output[2]"

      z.t.expect.status.is.true
    }
  }

  z.t.context "本体の収集中に監視を終了する場合"; {
    z.t.it "監視を終了すると収集中のメソッド名を消去する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug
      z.cls.capture._start captured_method stack=test_stack file=test_file

      z.cls.capture._stop

      z.t.expect.is.null "$z_cls_capture_method"
    }
  }

  z.t.context "元のDEBUGトラップがリスト形式の場合"; {
    z.t.it "クラスの公開後に元のリスト形式のDEBUGトラップを復元する"; {
      local -a output=()
      output=("${(@f)$(
        trap ': original' DEBUG
        local original=$(trap)

        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local source_status=$?

        local restored=$(trap)
        trap - DEBUG
        print -rl -- "$source_status" "${(qqqq)original}" "${(qqqq)restored}"
      )}")

      z.t.expect "${#output}" 3
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
    }
  }

  z.t.context "元のDEBUGトラップが標準出力へ書く場合"; {
    z.t.it "標準出力へ書くDEBUGトラップを復元する"; {
      local -a output=()
      output=("${(@f)$(
        trap 'print -rl -- "TRACE:$ZSH_DEBUG_CMD"' DEBUG
        local before=$(trap)
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local source_status=$?
        local after=$(trap)
        trap - DEBUG
        print -rl -- "$source_status" "${(qqqq)before}" "${(qqqq)after}"
      )}")

      z.arr.join.line "${output[@]}"

      z.t.expect.reply.includes TRACE:
      z.t.expect "$output[-3]" 0
      z.t.expect "$output[-1]" "$output[-2]"
    }
  }
}

z.t.describe "z.cls.capture._debug"; {
  z.t.context "通常のコマンドを収集する場合"; {
    z.t.it "コマンドを本体に追記しその場の実行を止める"; {
      z.cls.store._ensure
      z_cls_capture_method=record
      z_cls_capture_stack=''
      z_cls_capture_body=''

      z.cls.capture._debug 'print literal'
      local captured_errexit=$options[errexit]
      unsetopt errexit

      z.t.expect "$z_cls_capture_body" $'print literal\n'
      z.t.expect "$captured_errexit" on

      z_cls_capture_method=''
    }
  }

  z.t.context "ループと条件分岐を含む定義ファイルを読み込む場合"; {
    z.t.it "ループと条件分岐を実行し呼出元の変数を変更しない"; {
      local -a output=()
      output=("${(@f)$(
        local -i count=40
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$count"
        local first=""
        z.cls.new TestCounter first
        print -rl -- "$?"
        $first.loop
        print -rl -- "$REPLY" "$count"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 5
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 40
      z.t.expect "$output[3]" 0
      z.t.expect "$output[4]" default:one:two
      z.t.expect "$output[5]" 40
    }

  }

  z.t.context "メソッドを閉じず定義ファイルから戻る場合"; {
    z.t.it "メソッドの終端がなければ定義を破棄しDEBUGトラップを外す"; {
      local -a output=()
      output=("${(@f)$(
        source "$z_root/test/lib/cls/fixtures/unfinished.zsh"
        print -rl -- "$z_cls_capture_method:$z_cls_drawing" "${+functions[TRAPDEBUG]}"
        local first=""
        z.cls.new Unfinished first 2>/dev/null
        print -rl -- "$?"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 3
      z.t.expect "$output[1]" :
      z.t.expect "$output[2]" 0
      z.t.expect "$output[3]" 1
    }

  }

  z.t.context "クラスを閉じず定義ファイルから戻る場合"; {
    z.t.it "drewがなければ初期値を破棄しクラスを公開しない"; {
      local -a output=()
      output=("${(@f)$(
        source "$z_root/test/lib/cls/fixtures/missing-drew.zsh"
        print -rl -- "$z_cls_drawing:" "${+functions[TRAPDEBUG]}"
        print -rl -- "${+z_cls_defaults[MissingDrew:value]}" "${+z_cls_classes[MissingDrew]}"
      )}")

      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" :
      z.t.expect "$output[2]" 0
      z.t.expect "$output[3]" 0
      z.t.expect "$output[4]" 0
    }

  }

  z.t.context "メソッド名が不正な定義を読み込む場合"; {
    z.t.it "不正なメソッド名の本文を実行せず定義を破棄する"; {
      local -a output=()
      output=("${(@f)$(
        local -i side_effect=0
        source "$z_root/test/lib/cls/fixtures/invalid-header.zsh"
        print -rl -- "$side_effect" "$z_cls_drawing:$z_cls_capture_method"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" :
    }

  }

  z.t.context "メソッド内で別のクラスを宣言する場合"; {
    z.t.it "別のクラスはメソッドを実行したときに公開する"; {
      local -a output=()
      output=("${(@f)$(
        z.cls.draw MarkerOuter
          z.cls.method build
            z.cls.draw MarkerInner
              z.cls.attr value default=ready
            z.cls.drew
          z.cls.method.defined
        z.cls.drew

        print -r -- "${+z_cls_classes[MarkerInner]}"
        local outer=""
        z.cls.new MarkerOuter outer
        $outer.build

        local inner=""
        z.cls.new MarkerInner inner
        $inner.value.get
        print -r -- "$REPLY"
      )}")

      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" ready
    }

  }

  z.t.context "パイプやヒアドキュメントを含む本文を収集する場合"; {
    z.t.it "ヒアドキュメント内の終端マーカーを実行せず本文を保存する"; {
      local -a output=()
      output=("${(@f)$(
        source "$z_root/test/lib/cls/fixtures/body-syntax.zsh"
        local first=""
        z.cls.new SyntaxBox first
        $first.run test
        local call_status=$?
        local call_reply=$REPLY
        print -rl -- "$call_status" "$call_reply"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 9
      z.t.expect "$output[2]" value:test
    }
  }
}

z.t.describe "z.cls.capture._skip"; {
  z.t.context "定義中に別の定義をsourceした場合"; {
    z.t.it "入れ子の定義を読み飛ばして外側のクラスを公開する"; {
      local -a output=()
      output=("${(@f)$(
        trap ': ORIGINAL' DEBUG
        local original=$(trap)

        z.cls.draw Outer
          z.cls.attr kept default=outer
          source "$z_root/test/lib/cls/fixtures/rejected.zsh" 2>/dev/null
          print -r -- "$?"
          z.cls.attr added default=after
        z.cls.drew
        print -r -- "$?"

        local restored=$(trap)
        trap - DEBUG
        z.is.eq "$restored" "$original" && print -r -- restored

        local object=""
        z.cls.new Outer object
        $object.kept.get
        print -r -- "$REPLY"
        $object.added.get
        print -r -- "$REPLY"
        print -r -- "${+z_cls_classes[Rejected]}" "${+z_cls_classes[Deeper]}" "${+z_cls_classes[InMethod]}"
      )}")

      z.t.expect "${#output}" 6
      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" 0
      z.t.expect "$output[3]" restored
      z.t.expect "$output[4]" outer
      z.t.expect "$output[5]" after
      z.t.expect "$output[6]" "0 0 0"
    }
  }

  z.t.context "公開済みのクラスと同じ名前をsourceした場合"; {
    z.t.it "公開済みの同名クラスの初期値を上書きしない"; {
      local -a output=()
      output=("${(@f)$(
        z.cls.draw Rejected
          z.cls.attr kept default=original
        z.cls.drew

        source "$z_root/test/lib/cls/fixtures/rejected.zsh" 2>/dev/null
        print -r -- "$?"
        local object=""
        z.cls.new Rejected object
        $object.kept.get
        print -r -- "$REPLY"
      )}")

      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" original
    }
  }
}

z.t.describe "z.cls.capture._watch"; {
  z.t.context "DEBUGトラップを監視していない場合"; {
    z.t.it "監視を始めるとクラス用DEBUGトラップを登録する"; {
      z.cls.store._ensure
      z.cls.capture._watch
      z.var.exists 'functions[TRAPDEBUG]'
      local debug_status=$?

      z.cls.capture._stop

      z.t.expect "$debug_status" 0
    }
  }

  z.t.context "DEBUGトラップが呼出元のtrap_lineに代入する場合"; {
    z.t.it "退避中のDEBUGトラップが呼出元のtrap_lineを更新できる"; {
      local -a output=()
      output=("${(@f)$(
        local trap_line=before
        trap '
          if [[ $funcstack[1] == z.cls.capture._watch ]]; then
            trap_line="assigned by DEBUG"
          fi
        ' DEBUG
        local original=$(trap)

        z.cls.draw CaptureTrap
        z.cls.drew

        local restored=$(trap)
        trap - DEBUG
        print -rl -- "${(qqqq)original}" "${(qqqq)restored}" "$trap_line"
      )}")

      z.t.expect "${#output}" 3
      z.t.expect "$output[2]" "$output[1]"
      z.t.expect "$output[3]" "assigned by DEBUG"
    }
  }

  z.t.context "定義時のオプションを変更する場合"; {
    local -a option_sets=(
      localoptions
      localtraps
      nodebugbeforecmd
      "localoptions localtraps nodebugbeforecmd"
      nofunctionargzero
    )
    local option_set

    for option_set in "${option_sets[@]}"; do
      z.t.it "$option_set の設定を保持してメソッドを呼び出せる"; {
        local -a output=()
        output=("${(@f)$(
          z.str.split.shell "$option_set"
          setopt "${REPLY[@]}"
          local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
          source "$z_root/test/lib/cls/fixtures/counter.zsh"
          local source_status=$?
          local after="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"

          local first=""
          z.cls.new TestCounter first
          $first.increment
          print -rl -- "$source_status" "$before" "$after" "$REPLY"
        )}")

        z.t.expect.status.is.true
        z.t.expect "${#output}" 4
        z.t.expect "$output[1]" 0
        z.t.expect "$output[3]" "$output[2]"
        z.t.expect "$output[4]" 1
      }
    done
  }
}
