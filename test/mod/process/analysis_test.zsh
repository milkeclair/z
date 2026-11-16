source ${z_main}

z.t.describe "z.process._pids"; {
  z.t.context "対象の指定を検証する場合"; {
    local invalid
    for invalid in "" pid= pid=0 pid=-1 pid=+12 pid=2147483648 pid=99999999999999999999 pid=abc port= port=0 port=65536 port=99999999999999999999 port=-1 port=abc name= unknown=123 3000; do
      z.t.it "不正な指定[$invalid]を拒否する"; {
        z.process._pids "$invalid" 2>/dev/null
        z.t.expect.status.is.false
      }
    done

    z.t.it "指定なしと複数指定を拒否する"; {
      z.process._pids 2>/dev/null
      z.t.expect.status.is.false

      z.process._pids pid=123 port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "不正な指定の理由をstderrへ返す"; {
      local message=$(z.process._pids port=65536 2>&1)

      z.t.expect.includes "$message" "Invalid TCP port"
    }

    z.t.it "成功時は標準出力へ書き込まない"; {
      local output=$(z.process._pids pid=12345)

      z.t.expect "$output" ""
    }

    z.t.it "正のPIDをそのまま返す"; {
      z.process._pids pid=12345
      local lookup_status=$?
      local result=$REPLY

      z.t.expect "$lookup_status" 0
      z.t.expect "$result" 12345
    }
  }

  z.t.context "TCPポートを指定する場合"; {
    z.t.it "待受PIDだけを照会し重複を除去する"; {
      z.t.mock name=lsof behavior='
        z.is.eq "$*" "-nP -t -iTCP:3000 -sTCP:LISTEN" || return 2
        print -l -- 12345 23456 12345
      '

      z.process._pids port=3000
      local lookup_status=$?
      local pids=($REPLY)

      z.t.expect "$lookup_status" 0
      z.t.expect "${(j: :)pids}" "12345 23456"
    }

    z.t.it "該当なしでは失敗する"; {
      z.t.mock name=lsof behavior="return 1"

      z.process._pids port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "照会失敗時は部分的な出力を採用しない"; {
      z.t.mock name=lsof behavior="print -l -- 12345; return 2"

      z.process._pids port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "不正なPIDを含む結果を拒否する"; {
      z.t.mock name=lsof behavior="print -l -- 12345 -1"

      z.process._pids port=3000 2>/dev/null
      z.t.expect.status.is.false
    }
  }

  z.t.context "プロセス名を指定する場合"; {
    z.t.it "部分一致と正規表現を使わず完全一致で選ぶ"; {
      z.t.mock name=ps behavior='
        z.is.eq "$*" "-A -o pid= -o comm=" || return 2
        print -r -- " 12345 node"
        print -r -- " 23456 node-helper"
        print -r -- " 34567 node"
      '

      z.process._pids name=node
      local lookup_status=$?
      local pids=($REPLY)

      z.t.expect "$lookup_status" 0
      z.t.expect "${(j: :)pids}" "12345 34567"
    }

    z.t.it "特殊文字と空白を含む名前をリテラルとして扱う"; {
      z.t.mock name=ps behavior='print -r -- " 12345 n.[x] app"; print -r -- " 23456 n.x app"'

      z.process._pids "name=n.[x] app"

      z.t.expect.reply 12345
    }

    z.t.it "falseという名前を数値へ変換しない"; {
      z.t.mock name=ps behavior='print -r -- " 12345 false"'

      z.process._pids name=false

      z.t.expect.reply 12345
    }

    z.t.it "該当なしでは失敗する"; {
      z.t.mock name=ps behavior='print -r -- " 12345 another"'

      z.process._pids name=missing 2>/dev/null

      z.t.expect.status.is.false
    }

    z.t.it "psの失敗を伝える"; {
      z.t.mock name=ps behavior='print -r -- " 12345 node"; return 2'

      z.process._pids name=node 2>/dev/null

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.process.list"; {
  z.t.context "引数を指定しない場合"; {
    z.t.it "全件のPID・名前・TCP待受ポートを表示する"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"; print -r -- " 456 worker app"'
      z.t.mock name=lsof behavior='print -l -- p123 n"*:3000"'

      local output=$(z.process.list)

      z.t.expect "$output" $'PID\tNAME\tPORTS\n123\tnode\t3000\n456\tworker app\t-'
    }

    z.t.it "ヘッダーを除いた行をREPLYにも返す"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"'
      z.t.mock name=lsof behavior="return 1"

      z.process.list >/dev/null
      local list_status=$?
      local result=$REPLY

      z.t.expect "$list_status" 0
      z.t.expect "$result" $'123\tnode\t-'
    }
  }

  z.t.context "selectorを指定した場合"; {
    z.t.it "PIDで絞り込む"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"; print -r -- " 456 worker"'
      z.t.mock name=lsof behavior="return 1"

      local output=$(z.process.list pid=456)

      z.t.expect "$output" $'PID\tNAME\tPORTS\n456\tworker\t-'
    }

    z.t.it "名前を完全一致で絞り込む"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"; print -r -- " 456 node-helper"'
      z.t.mock name=lsof behavior="return 1"

      local output=$(z.process.list name=node)

      z.t.expect "$output" $'PID\tNAME\tPORTS\n123\tnode\t-'
    }

    z.t.it "ポートで対象を選びそのプロセスの待受ポートを表示する"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"; print -r -- " 456 worker"'
      z.t.mock name=lsof behavior='
        if z.is.eq "$*" "-nP -t -iTCP:3000 -sTCP:LISTEN"; then
          print -l -- 123
        else
          print -l -- p123 n"*:3000" n"[::1]:4000"
        fi
      '

      local output=$(z.process.list port=3000)

      z.t.expect "$output" $'PID\tNAME\tPORTS\n123\tnode\t3000,4000'
    }

    z.t.it "存在しないPIDで空の一覧を成功扱いしない"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"'
      z.t.mock name=lsof behavior="return 1"

      z.process.list pid=456 >/dev/null 2>&1

      z.t.expect.status.is.false
    }

    z.t.it "複数selectorを拒否する"; {
      z.process.list pid=123 name=node >/dev/null 2>&1

      z.t.expect.status.is.false
    }
  }

  z.t.context "照会が失敗した場合"; {
    z.t.it "psの失敗を返し一覧を表示しない"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"; return 1'
      z.t.mock name=lsof behavior="return 1"

      z.process.list >/dev/null 2>&1

      z.t.expect.status.is.false
    }

    z.t.it "ポート取得の失敗を返す"; {
      z.t.mock name=ps behavior='print -r -- " 123 node"'
      z.t.mock name=lsof behavior="return 127"

      z.process.list >/dev/null 2>&1

      z.t.expect.status.is.false
    }
  }
}
