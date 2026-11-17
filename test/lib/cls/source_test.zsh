source ${z_main}

# DEBUGトラップを隔離した処理から結果を受け取り、検証は親のテストで行う。

z.t.describe "z.clsのsource"; {
  z.t.context "定義ファイルを読み込む場合"; {
    z.t.it "本体の実行を保留し、制御構文と呼出元の変数を保つ"; {
      local -a output=()
      output=("${(@f)$(
        local -i count=40
        source "$z_root/test/lib/cls/counter.zsh"
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
        source "$z_root/test/lib/cls/unfinished.zsh"
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

    z.t.it "無効なメソッド名の本体を実行せず定義を破棄する"; {
      local -a output=()
      output=("${(@f)$(
        local -i side_effect=0
        source "$z_root/test/lib/cls/invalid-header.zsh"
        print -rl -- "$side_effect" "$z_cls_drawing:$z_cls_capture_method"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" :
    }

    z.t.it "パイプ、ヒアドキュメント、条件付きコマンドを保存する"; {
      local -a output=()
      output=("${(@f)$(
        source "$z_root/test/lib/cls/body-syntax.zsh"
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
        source "$z_root/test/lib/cls/counter.zsh"
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
        source "$z_root/test/lib/cls/counter.zsh"
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
        source "$z_root/test/lib/cls/counter.zsh"
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
