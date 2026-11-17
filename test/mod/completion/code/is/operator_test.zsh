source "$z_main"

z.t.describe "z.completion.code.is._active"; {
  z.t.context "補完外またはコマンド名の位置の場合"; {
    z.t.it "補完外とコマンド名の位置では失敗する"; {
      z.completion.code.is._active
      z.t.expect.status.is.false

      local -A compstate=([context]=command)
      local words=(run)
      local CURRENT=1
      z.completion.code.is._active
      z.t.expect.status.is.false
    }
  }

  z.t.context "補完の引数位置の場合"; {
    z.t.it "補完の引数位置では成功する"; {
      local -A compstate=([context]=command)
      local words=(run code=print)
      local CURRENT=2
      z.completion.code.is._active

      z.t.expect.status.is.true
    }
  }

  z.t.context "単語が文字数上限を越える場合"; {
    z.t.it "文字数上限を越えた単語では失敗する"; {
      local -A compstate=([context]=command)
      local oversized=$(printf "%1048577s" "")
      local words=(run "$oversized")
      local CURRENT=2
      z.completion.code.is._active

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.completion.code.is._literal"; {
  z.t.context "値が許可値に完全一致する場合"; {
    z.t.it "空白のある許可値とも完全一致で比較する"; {
      local example_values=("a b" "other")
      z.completion.code.is._literal "value=a b" literals=example_values

      z.t.expect.status.is.true
    }

    z.t.it "空値とdefault=を予約引数として解釈しない"; {
      local example_values=("" "default=x")
      z.completion.code.is._literal value= literals=example_values

      z.t.expect.status.is.true
    }
  }

  z.t.context "値が許可値にない場合"; {
    z.t.it "許可値にない値では失敗する"; {
      local example_values=(noop)
      z.completion.code.is._literal value=print literals=example_values

      z.t.expect.status.is.false
    }
  }
}
