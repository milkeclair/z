source ${z_main}

z.t.describe "z.process.list._ports"; {
  z.t.context "TCP待受がある場合"; {
    z.t.it "IPv4・IPv6・wildcardのポートをPIDごとにまとめる"; {
      z.t.mock name=lsof behavior='
        z.is.eq "$*" "-nP -w -iTCP -sTCP:LISTEN -Fpn" || return 2
        print -l -- p123 n127.0.0.1:3000 n"[::1]:80" n"*:3000" p456 n"*:5432"
      '

      z.process.list._ports
      local lookup_status=$?
      local -A ports=($REPLY)

      z.t.expect "$lookup_status" 0
      z.t.expect "$ports[123]" "80,3000"
      z.t.expect "$ports[456]" 5432
    }
  }

  z.t.context "TCP待受がない場合"; {
    z.t.it "空の対応表を返す"; {
      z.t.mock name=lsof behavior="return 1"

      z.process.list._ports
      local lookup_status=$?
      local result=$REPLY

      z.t.expect "$lookup_status" 0
      z.t.expect "$result" ""
    }
  }

  z.t.context "取得できない場合"; {
    z.t.it "stderrを伴う失敗を該当なしと区別する"; {
      z.t.mock name=lsof behavior='print -u2 -- "lookup failed"; return 1'

      z.process.list._ports 2>/dev/null

      z.t.expect.status.is.false
    }

    z.t.it "依存コマンドの失敗を返す"; {
      z.t.mock name=lsof behavior="return 127"

      z.process.list._ports 2>/dev/null

      z.t.expect.status.is.false
    }

    z.t.it "失敗時の部分出力を返さない"; {
      z.t.mock name=lsof behavior='print -l -- p123 n"*:3000"; return 2'

      z.process.list._ports 2>/dev/null
      local lookup_status=$?
      local result=$REPLY

      z.t.expect "$lookup_status" 1
      z.t.expect "$result" ""
    }

    local record
    for record in 'n*:3000' $'p123\nn*:not-a-port' $'p123\nunexpected'; do
      z.t.it "不正なレコードを拒否する"; {
        z.t.mock name=lsof behavior="print -r -- ${(q)record}"

        z.process.list._ports 2>/dev/null

        z.t.expect.status.is.false
      }
    done
  }
}
