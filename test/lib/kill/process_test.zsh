source ${z_main}

z.t.describe "z.kill"; {
  z.t.context "対象のPIDが得られる場合"; {
    z.t.it "対象へTERMを送りPIDを返す"; {
      z.t.mock name="z.kill._pids" behavior="z.return 12345 23456"
      z.t.mock name=kill

      z.kill port=3000
      local kill_status=$?
      local pids=($REPLY)

      z.t.mock.result name=kill
      local sent=$REPLY

      z.t.expect "$kill_status" 0
      z.t.expect "${(j: :)pids}" "12345 23456"
      z.t.expect "$sent" "-TERM -- 12345 -TERM -- 23456"
    }

    z.t.it "途中で失敗しても残りに送信し成功したPIDを返す"; {
      z.t.mock name="z.kill._pids" behavior="z.return 12345 23456 34567"
      z.t.mock name=kill behavior='if z.is.eq "$3" 23456; then return 1; fi'

      z.kill name=node
      local kill_status=$?
      local pids=($REPLY)

      z.t.expect "$kill_status" 1
      z.t.expect "${(j: :)pids}" "12345 34567"
    }

    z.t.it "送信が失敗するとfalseを返す"; {
      z.t.mock name="z.kill._pids" behavior="z.return 12345"
      z.t.mock name=kill behavior="return 1"

      z.kill pid=12345
      local kill_status=$?
      local result=$REPLY

      z.t.expect "$kill_status" 1
      z.t.expect "$result" ""
    }
  }

  z.t.context "対象を取得できない場合"; {
    z.t.it "killを実行せずREPLYを空にする"; {
      z.t.mock name="z.kill._pids" behavior="z.return 12345; return 1"
      z.t.mock name=kill

      z.kill port=3000
      local kill_status=$?
      local result=$REPLY

      z.t.mock.result name=kill
      local sent=$REPLY

      z.t.expect "$kill_status" 1
      z.t.expect "$result" ""
      z.t.expect "$sent" ""
    }
  }

  z.t.context "実際の子プロセスを指定する場合"; {
    z.t.it "このテストで起動したプロセスを終了する"; {
      sleep 30 &
      local child_pid=$!

      z.kill pid=$child_pid
      local kill_status=$?
      local result=$REPLY
      if z.int.is.not.zero "$kill_status"; then
        builtin kill -TERM -- "$child_pid" 2>/dev/null
      fi
      wait "$child_pid" 2>/dev/null
      local wait_status=$?

      z.t.expect "$kill_status" 0
      z.t.expect "$result" "$child_pid"
      z.t.expect "$wait_status" 143
    }
  }
}
