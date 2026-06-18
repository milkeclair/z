source ${z_main}

z.t.describe "z.wtproxy._port.is.used"; {
  z.t.context "指定したportがused portsに含まれる場合"; {
    z.t.it "trueを返す"; {
      z.wtproxy._port.is.used 3000 3001 3000

      z.t.expect.status.is.true
    }
  }

  z.t.context "指定したportがused portsに含まれない場合"; {
    z.t.it "falseを返す"; {
      z.wtproxy._port.is.used 3002 3001 3000

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.wtproxy._port.is.free"; {
  z.t.context "portをlistenできる場合"; {
    z.t.it "closeしてtrueを返す"; {
      z.t.mock name="ztcp" behavior='
        if z.is.eq "$1" "-l"; then
          REPLY=12
        fi
      '

      z.wtproxy._port.is.free 41080

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="ztcp"
      z.t.expect.reply.is.arr "-l 41080" "-c 12"
    }
  }

  z.t.context "portをlistenできない場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="ztcp" behavior="return 1"

      z.wtproxy._port.is.free 41080

      z.t.expect.status.is.false
    }
  }
}
