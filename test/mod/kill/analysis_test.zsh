source ${z_main}

z.t.describe "z.kill._pids"; {
  z.t.context "対象の指定を検証する場合"; {
    local invalid
    for invalid in "" pid= pid=0 pid=-1 pid=+12 pid=2147483648 pid=99999999999999999999 pid=abc port= port=0 port=65536 port=99999999999999999999 port=-1 port=abc name= unknown=123 3000; do
      z.t.it "不正な指定[$invalid]を拒否する"; {
        z.kill._pids "$invalid" 2>/dev/null
        z.t.expect.status.is.false
      }
    done

    z.t.it "指定なしと複数指定を拒否する"; {
      z.kill._pids 2>/dev/null
      z.t.expect.status.is.false

      z.kill._pids pid=123 port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "不正な指定の理由をstderrへ返す"; {
      local message=$(z.kill._pids port=65536 2>&1)

      z.t.expect.includes "$message" "Invalid TCP port"
    }

    z.t.it "成功時は標準出力へ書き込まない"; {
      local output=$(z.kill._pids pid=12345)

      z.t.expect "$output" ""
    }

    z.t.it "正のPIDをそのまま返す"; {
      z.kill._pids pid=12345
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

      z.kill._pids port=3000
      local lookup_status=$?
      local pids=($REPLY)

      z.t.expect "$lookup_status" 0
      z.t.expect "${(j: :)pids}" "12345 23456"
    }

    z.t.it "該当なしでは失敗する"; {
      z.t.mock name=lsof behavior="return 1"

      z.kill._pids port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "照会失敗時は部分的な出力を採用しない"; {
      z.t.mock name=lsof behavior="print -l -- 12345; return 2"

      z.kill._pids port=3000 2>/dev/null
      z.t.expect.status.is.false
    }

    z.t.it "不正なPIDを含む結果を拒否する"; {
      z.t.mock name=lsof behavior="print -l -- 12345 -1"

      z.kill._pids port=3000 2>/dev/null
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

      z.kill._pids name=node
      local lookup_status=$?
      local pids=($REPLY)

      z.t.expect "$lookup_status" 0
      z.t.expect "${(j: :)pids}" "12345 34567"
    }

    z.t.it "特殊文字と空白を含む名前をリテラルとして扱う"; {
      z.t.mock name=ps behavior='print -r -- " 12345 n.[x] app"; print -r -- " 23456 n.x app"'

      z.kill._pids "name=n.[x] app"

      z.t.expect.reply 12345
    }

    z.t.it "falseという名前を数値へ変換しない"; {
      z.t.mock name=ps behavior='print -r -- " 12345 false"'

      z.kill._pids name=false

      z.t.expect.reply 12345
    }

    z.t.it "該当なしでは失敗する"; {
      z.t.mock name=ps behavior='print -r -- " 12345 another"'

      z.kill._pids name=missing 2>/dev/null

      z.t.expect.status.is.false
    }

    z.t.it "psの失敗を伝える"; {
      z.t.mock name=ps behavior='print -r -- " 12345 node"; return 2'

      z.kill._pids name=node 2>/dev/null

      z.t.expect.status.is.false
    }
  }
}
