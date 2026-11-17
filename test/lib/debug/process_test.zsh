source ${z_main}

z.t.describe "z.debug"; {
  z.t.context "whenceで関数を検索した場合"; {
    z.t.it "定義されている"; {
      whence -w z.debug | grep -q "z.debug: function"

      z.t.expect.status.is.true
    }
  }

  z.t.context "zの他の関数を読み込まずに実行した場合"; {
    z.t.it "変数を表示してREPLYを保持する"; {
      local input=$'p sample\nc'
      local output=$(zsh -fc '
        source "$1"
        local sample="standalone value"
        Z_DEBUG=0
        REPLY=kept
        z.debug
        print -r -- "REPLY:$REPLY"
      ' -- "$z_root/lib/debug/process.zsh" <<< "$input" 2>&1)

      z.t.expect.includes "$output" "standalone value"
      z.t.expect.includes "$output" "REPLY:kept"
      z.t.expect.excludes "$output" "command not found"
    }
  }

  z.t.context "Z_DEBUGが0の場合"; {
    z.t.it "デバッガーに入る"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.is.false
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "Z_DEBUGが1の場合"; {
    z.t.it "デバッガーに入らない"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=1

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.is.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "cを入力した場合"; {
    z.t.it "デバッガーを抜ける"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "c") >/dev/null 2>&1

      z.t.expect.status.is.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "continueを入力した場合"; {
    z.t.it "デバッガーを抜ける"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "continue") >/dev/null 2>&1

      z.t.expect.status.is.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "qを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.is.false
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "quitを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "quit") >/dev/null 2>&1

      z.t.expect.status.is.false
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "exitを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "exit") >/dev/null 2>&1

      z.t.expect.status.is.false
      Z_DEBUG=$previous_debug
    }
  }
}

z.t.describe "z.debug.enable"; {
  z.t.context "Z_DEBUGが1の場合"; {
    z.t.it "Z_DEBUGを0に設定する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=1

      z.debug.enable

      z.t.expect $Z_DEBUG 0
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "Z_DEBUGが0の場合"; {
    z.t.it "Z_DEBUGを0から変更しない"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      z.debug.enable

      z.t.expect $Z_DEBUG 0
      Z_DEBUG=$previous_debug
    }
  }
}

z.t.describe "z.debug.disable"; {
  z.t.context "Z_DEBUGが1の場合"; {
    z.t.it "Z_DEBUGを1から変更しない"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=1

      z.debug.disable

      z.t.expect $Z_DEBUG 1
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "Z_DEBUGが0の場合"; {
    z.t.it "Z_DEBUGを1に設定する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      z.debug.disable

      z.t.expect $Z_DEBUG 1
      Z_DEBUG=$previous_debug
    }
  }
}
