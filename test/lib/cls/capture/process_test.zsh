source ${z_main}

# DEBUGトラップを隔離した処理から結果を受け取り、検証は親のテストで行う。

# オプションを隔離した処理から結果を受け取り、検証は親のテストで行う。

z.t.describe "z.cls.capture._start"; {
  z.t.context "DEBUG捕捉を開始する場合"; {
    z.t.it "メソッド名と呼出元を保持する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug behavior='local REPLY=""'
      REPLY=(before "two words" "")

      z.cls.capture._start captured_method test_stack test_file 0
      local -a preserved_reply=("${REPLY[@]}")
      local installed_debug=${+functions[TRAPDEBUG]}
      local captured_name=$z_cls_capture_method
      local captured_stack=$z_cls_capture_stack
      z.cls.capture._stop

      z.t.expect "$installed_debug" 1
      z.t.expect "$captured_name" captured_method
      z.t.expect "$captured_stack" test_stack
      z.t.expect "${#preserved_reply}" 3
      z.t.expect "$preserved_reply[1]" before
      z.t.expect "$preserved_reply[2]" "two words"
      z.t.expect.is.null "$preserved_reply[3]"
    }
  }
}

z.t.describe "z.cls.capture._stop"; {
  z.t.context "DEBUG捕捉を終了する場合"; {
    z.t.it "元の関数形式トラップを復元する"; {
      z.cls.store._ensure
      z.t.mock name=z.cls.capture._debug
      TRAPDEBUG() {
        return 0
      }

      local original_debug=$functions[TRAPDEBUG]
      z.cls.capture._start captured_method test_stack test_file 0

      z.cls.capture._stop

      z.t.expect "$functions[TRAPDEBUG]" "$original_debug"
      z.t.expect.is.null "$z_cls_capture_method"

      unfunction TRAPDEBUG
    }
  }

  z.t.context "既存のDEBUGトラップがある場合"; {
    z.t.it "関数形式のトラップを復元し、元のトラップも実行する"; {
      local -a output=()
      output=("${(@f)$(
        local -i trap_calls=0
        TRAPDEBUG() {
          (( ++trap_calls ))
          return 0
        }

        local before=$functions[TRAPDEBUG]
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local after=$functions[TRAPDEBUG]
        local calls=$trap_calls
        local first=""
        z.cls.new TestCounter first
        first.increment
        local call_reply=$REPLY
        unfunction TRAPDEBUG
        print -rl -- "${(qqqq)before}" "${(qqqq)after}" "$calls" "$call_reply"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[2]" "$output[1]"
      z.int.is.gt "$output[3]" 0

      z.t.expect.status.is.true
      z.t.expect "$output[4]" 1
    }

    z.t.it "リスト形式のトラップを復元する"; {
      local -a output=()
      output=("${(@f)$(
        local -i trap_calls=0
        trap '(( ++trap_calls ))' DEBUG
        local before=$(trap)
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        local after=$(trap)
        local first=""
        z.cls.new TestCounter first
        first.increment
        local call_reply=$REPLY
        trap - DEBUG
        print -rl -- "${(qqqq)before}" "${(qqqq)after}" "$call_reply"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 3
      z.t.expect "$output[2]" "$output[1]"
      z.t.expect "$output[3]" 1
    }

    z.t.it "標準出力へ表示するトラップも復元する"; {
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

      z.t.expect.status.is.true
      z.t.expect.includes "${(j:\n:)output}" TRACE:
      z.t.expect "$output[-3]" 0
      z.t.expect "$output[-1]" "$output[-2]"
    }
  }
}

z.t.describe "z.cls.capture._debug"; {
  z.t.context "通常の本体を捕捉する場合"; {
    z.t.it "コマンドを保存してerrexitで実行を抑制する"; {
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

  z.t.context "定義ファイルを読み込む場合"; {
    z.t.it "本体の実行を保留し、制御構文と呼出元の変数を保つ"; {
      local -a output=()
      output=("${(@f)$(
        local -i count=40
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$count"
        local first=""
        z.cls.new TestCounter first
        print -rl -- "$?"
        first.loop
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

    z.t.it "終了マーカーがない定義を破棄してトラップを復元する"; {
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

    z.t.it "クラスの終端を欠いた場合も定義を破棄しトラップを復元する"; {
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

    z.t.it "無効なメソッド名の本体を実行せず定義を破棄する"; {
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

    z.t.it "メソッド内のdrawとdrewは呼び出すまで実行しない"; {
      local -a output=()
      output=("${(@f)$(
        z.cls.draw MarkerOuter
          z.cls.fn build
            z.cls.draw MarkerInner
              z.cls.attr value default=ready
            z.cls.drew
          z.cls.fn.done
        z.cls.drew

        print -r -- "${+z_cls_classes[MarkerInner]}"
        local outer=""
        z.cls.new MarkerOuter outer
        outer.build

        local inner=""
        z.cls.new MarkerInner inner
        inner.value.get
        print -r -- "$REPLY"
      )}")

      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" ready
    }

    z.t.it "パイプ、ヒアドキュメント、条件付きコマンドを保存する"; {
      local -a output=()
      output=("${(@f)$(
        source "$z_root/test/lib/cls/fixtures/body-syntax.zsh"
        local first=""
        z.cls.new SyntaxBox first
        first.run test
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
    z.t.it "対応するdrewまで実行を抑止し、外側の定義を維持する"; {
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
        [[ $restored == "$original" ]] && print -r -- restored

        local object=""
        z.cls.new Outer object
        object.kept.get
        print -r -- "$REPLY"
        object.added.get
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
    z.t.it "定義を上書きせず終端で失敗する"; {
      local -a output=()
      output=("${(@f)$(
        z.cls.draw Rejected
          z.cls.attr kept default=original
        z.cls.drew

        source "$z_root/test/lib/cls/fixtures/rejected.zsh" 2>/dev/null
        print -r -- "$?"
        local object=""
        z.cls.new Rejected object
        object.kept.get
        print -r -- "$REPLY"
      )}")

      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" original
    }
  }
}

z.t.describe "z.cls.capture._watch"; {
  z.t.context "定義時のオプションを変更する場合"; {
    z.t.it "localoptionsの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localoptions
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "localtrapsの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localtraps
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "nodebugbeforecmdの設定を保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nodebugbeforecmd
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "複数の設定を同時に保持してメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt localoptions localtraps nodebugbeforecmd
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }

    z.t.it "functionargzeroが無効でもメソッドを呼び出せる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nofunctionargzero
        local before="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        source "$z_root/test/lib/cls/fixtures/counter.zsh"
        print -rl -- "$?" "$before" "$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]:$options[functionargzero]"
        local first=""
        z.cls.new TestCounter first
        first.increment
        print -rl -- "$REPLY"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 4
      z.t.expect "$output[1]" 0
      z.t.expect "$output[3]" "$output[2]"
      z.t.expect "$output[4]" 1
    }
  }

}
