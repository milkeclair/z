source ${z_main}

z.t.describe "z.wtproxy.start._serve.pipe.pair"; {
  z.t.context "zselectが失敗した場合"; {
    z.t.it "両方のfdをcloseして終了する"; {
      local calls=/tmp/z_t/wtproxy_pipe_close_calls
      z.dir.make path=${calls:h}
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior="return 1"
      z.t.mock name="ztcp" behavior='print -r -- "$*" >> /tmp/z_t/wtproxy_pipe_close_calls'

      (z.wtproxy.start._serve.pipe.pair 11 12)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "-c 11"
      z.t.expect.includes "$content" "-c 12"
    }
  }

  z.t.context "片方のfdがreadyになった場合"; {
    z.t.it "反対側のfdへsysreadする"; {
      local calls=/tmp/z_t/wtproxy_pipe_sysread_calls
      z.dir.make path=${calls:h}
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable sysread 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior='
        eval "$2[$3]=1"
      '
      z.t.mock name="sysread" behavior='
        print -r -- "$*" >> /tmp/z_t/wtproxy_pipe_sysread_calls
        return 1
      '
      z.t.mock name="ztcp" behavior=":"

      (z.wtproxy.start._serve.pipe.pair 11 12)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "-i 11 -o 12 -s 8192"
    }
  }
}
