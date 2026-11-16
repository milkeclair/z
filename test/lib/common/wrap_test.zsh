source ${z_main}

z.t.describe "z.return"; {
  z.t.context "0を指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return 0

      z.t.expect.reply 0
    }
  }

  z.t.context "trueを指定した場合"; {
    z.t.it "REPLYに0を設定する"; {
      z.return "true"

      z.t.expect.reply 0
    }
  }

  z.t.context "1を指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return 1

      z.t.expect.reply 1
    }
  }

  z.t.context "falseを指定した場合"; {
    z.t.it "REPLYに1を設定する"; {
      z.return "false"

      z.t.expect.reply 1
    }
  }

  z.t.context "nullを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return

      z.t.expect.reply.is.null
    }
  }

  z.t.context "voidを指定した場合"; {
    z.t.it "REPLYに空文字を設定する"; {
      z.return "void"

      z.t.expect.reply.is.null
    }
  }

  z.t.context "その他の値を指定した場合"; {
    z.t.it "REPLYにそのままの値を設定する"; {
      z.return "sample_value"

      z.t.expect.reply "sample_value"
    }
  }

  z.t.context "複数の値を指定した場合"; {
    z.t.it "REPLYに配列として設定する"; {
      z.return "value1" "value2" "value3"

      z.t.expect.reply.is.arr "value1" "value2" "value3"
    }
  }

  z.t.context "keep_empty=trueを指定して複数の値を渡した場合"; {
    z.t.it "空要素を保持してREPLYに配列を設定する"; {
      z.return keep_empty=true "value1" "" "value3"

      z.t.expect.reply.is.arr "value1" "" "value3"
    }
  }

  z.t.context "keep_emptyを指定せず空要素を含む複数の値を渡した場合"; {
    z.t.it "空要素は除外される"; {
      z.return "value1" "" "value3"

      z.t.expect.reply.is.arr "value1" "value3"
    }
  }

  z.t.context "keep_emptyが複数回指定される場合"; {
    z.t.it "falseの間だけ指定を読み取り、true以降はデータとして残す"; {
      () {
        local REPLY
        z.return keep_empty=false keep_empty=true keep_empty=false "a" "" "b" &&
          local -a result=("${REPLY[@]}")
        z.t.expect.status.is.true
        z.t.expect "${#result[@]}" 4
        z.t.expect "${result[1]}" "keep_empty=false"
        z.t.expect "${result[2]}" "a"
        z.t.expect.is.null "${result[3]}"
        z.t.expect "${result[4]}" "b"
      }
    }
  }

  z.t.context "空文字と真偽値が複数要素として渡される場合"; {
    z.t.it "要素数を判定してから空要素を除き、配列内の真偽値は変換しない"; {
      () {
        local REPLY
        z.return "" true
        local -a result=("${REPLY[@]}")

        z.t.expect "${#result[@]}" 1
        z.t.expect "${result[1]}" "true"
      }
    }
  }

  z.t.context "keep_emptyに数値または未知の値を渡す場合"; {
    z.t.it "0をtrueとして扱い、未知の値では空要素を除く"; {
      () {
        local REPLY
        z.return keep_empty=0 "a" "" "b"
        local -a kept=("${REPLY[@]}")
        z.return keep_empty=other "a" "" "b"
        local -a dropped=("${REPLY[@]}")

        z.t.expect "${#kept[@]}" 3
        z.t.expect.is.null "${kept[2]}"
        z.t.expect "${#dropped[@]}" 2
        z.t.expect "${dropped[1]}" "a"
        z.t.expect "${dropped[2]}" "b"
      }
    }
  }

  z.t.context "単一値を返す場合"; {
    z.t.it "空白を含む値と終了ステータスを保持する"; {
      () {
        local REPLY=sentinel
        z.return "two words" && local result_reply=$REPLY
        z.t.expect.status.is.true
        z.t.expect "$result_reply" "two words"
      }
    }

    z.t.it "単独のkeep_empty指定は制御引数として消費する"; {
      z.return keep_empty=other
      z.t.expect.reply.is.null
    }
  }
}

z.t.describe "z.return.hash"; {
  z.t.context "ハッシュが渡された場合"; {
    z.t.it "REPLYにキーと値のペアの配列を設定する"; {
      local -A hash
      hash[name]="John"
      hash[age]="30"

      z.return.hash hash
      local -A result=($REPLY)

      z.t.expect ${result[name]} "John"
      z.t.expect ${result[age]} "30"
    }
  }

  z.t.context "空のハッシュが渡された場合"; {
    z.t.it "REPLYを空に設定する"; {
      local -A empty_hash

      z.return.hash empty_hash

      z.t.expect.reply.is.null
    }
  }
}
