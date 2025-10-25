source ${z_main}

z.t.describe "z.debug"; {
  z.t.context "whenceで関数を検索した場合"; {
    z.t.it "定義されている"; {
      whence -w z.debug | grep -q "z.debug: function"

      z.t.expect.status.true
    }
  }

  z.t.context "Z_DEBUGが0の場合"; {
    z.t.it "デバッガーに入る"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "Z_DEBUGが1の場合"; {
    z.t.it "デバッガーに入らない"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=1

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "cを入力した場合"; {
    z.t.it "デバッガーを抜ける"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "c") >/dev/null 2>&1

      z.t.expect.status.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "continueを入力した場合"; {
    z.t.it "デバッガーを抜ける"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "continue") >/dev/null 2>&1

      z.t.expect.status.true
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "qを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "q") >/dev/null 2>&1

      z.t.expect.status.false
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "quitを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "quit") >/dev/null 2>&1

      z.t.expect.status.false
      Z_DEBUG=$previous_debug
    }
  }

  z.t.context "exitを入力した場合"; {
    z.t.it "プロセスが終了する"; {
      local previous_debug=$Z_DEBUG
      Z_DEBUG=0

      (z.debug <<< "exit") >/dev/null 2>&1

      z.t.expect.status.false
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
