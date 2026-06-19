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

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
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

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "-i 11 -o 12 -s 8192"
    }
  }

  z.t.context "active pathが同じ場合"; {
    z.t.it "反対側のfdへsysreadする"; {
      local calls=/tmp/z_t/wtproxy_pipe_active_same_sysread_calls
      z.dir.make path=${calls:h}
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable sysread 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior="
        eval \"\$2[\$3]=1\"
      "
      z.t.mock name="z.wtproxy._entry.active" behavior="
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      "
      z.t.mock name="sysread" behavior="
        print -r -- \"\$*\" >> /tmp/z_t/wtproxy_pipe_active_same_sysread_calls
        return 1
      "
      z.t.mock name="ztcp" behavior=":"

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "-i 11 -o 12 -s 8192"
    }
  }

  z.t.context "2回目のclient dataでactive pathが変わった場合"; {
    z.t.it "最初のsysread後に両方のfdをcloseして終了する"; {
      local calls=/tmp/z_t/wtproxy_pipe_active_changed_calls
      z.dir.make path=${calls:h}
      z.file.write path=$calls content=""
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable sysread 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior="
        eval \"\$2[\$3]=1\"
      "
      z.t.mock name="z.wtproxy._entry.active" behavior="
        local -A entry=(path /tmp/other-worktree)
        z.return.hash entry
      "
      z.t.mock name="sysread" behavior="
        print -r -- \"sysread \$*\" >> /tmp/z_t/wtproxy_pipe_active_changed_calls
      "
      z.t.mock name="ztcp" behavior="
        print -r -- \"ztcp \$*\" >> /tmp/z_t/wtproxy_pipe_active_changed_calls
      "

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "ztcp -c 11"
      z.t.expect.includes "$content" "ztcp -c 12"
      z.t.expect.includes "$content" "sysread -i 11 -o 12 -s 8192"
    }
  }

  z.t.context "state fileのactive pathが同じ場合"; {
    z.t.it "active entryを読まずに2回目のclient dataをsysreadする"; {
      local state_file=/tmp/z_t/wtproxy_pipe_state_active_same/state
      local calls=/tmp/z_t/wtproxy_pipe_state_active_same/calls
      z.dir.make path=${state_file:h}
      z.file.write path=$state_file content="active \"/tmp/worktree\""
      z.file.write path=$calls content=""
      z_wtproxy_serve_state_file=$state_file
      typeset -g z_t_wtproxy_pipe_sysread_count=0
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable sysread 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior="
        eval \"\$2[\$3]=1\"
      "
      z.t.mock name="z.wtproxy._entry.active" behavior="
        print -r -- \"active\" >> /tmp/z_t/wtproxy_pipe_state_active_same/calls
        return 1
      "
      z.t.mock name="sysread" behavior="
        z_t_wtproxy_pipe_sysread_count=\$((z_t_wtproxy_pipe_sysread_count + 1))
        print -r -- \"sysread \$z_t_wtproxy_pipe_sysread_count \$*\" >> /tmp/z_t/wtproxy_pipe_state_active_same/calls
        if (( z_t_wtproxy_pipe_sysread_count >= 2 )); then
          return 1
        fi
        return 0
      "
      z.t.mock name="ztcp" behavior=":"

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "sysread 1 -i 11 -o 12 -s 8192" skip_unmock=true
      z.t.expect.includes "$content" "sysread 2 -i 11 -o 12 -s 8192" skip_unmock=true
      z.t.expect.excludes "$content" "active"
      z_wtproxy_serve_state_file=""
      z_t_wtproxy_pipe_sysread_count=0
    }
  }

  z.t.context "upstream側のfdがreadyでactive pathが変わっている場合"; {
    z.t.it "active entryを読まずにclient fdへsysreadする"; {
      local calls=/tmp/z_t/wtproxy_pipe_upstream_ready_calls
      z.dir.make path=${calls:h}
      z.file.write path=$calls content=""
      disable zmodload 2>/dev/null
      disable zselect 2>/dev/null
      disable sysread 2>/dev/null
      disable ztcp 2>/dev/null
      z.t.mock name="zmodload" behavior=":"
      z.t.mock name="zselect" behavior="
        eval \"\$2[\$4]=1\"
      "
      z.t.mock name="z.wtproxy._entry.active" behavior="
        print -r -- \"active\" >> /tmp/z_t/wtproxy_pipe_upstream_ready_calls
        return 1
      "
      z.t.mock name="sysread" behavior="
        print -r -- \"\$*\" >> /tmp/z_t/wtproxy_pipe_upstream_ready_calls
        return 1
      "
      z.t.mock name="ztcp" behavior=":"

      (z.wtproxy.start._serve.pipe.pair 11 12 /tmp/worktree)
      local content=$(cat $calls)

      z.t.expect.includes "$content" "-i 12 -o 11 -s 8192"
      z.t.expect.excludes "$content" "active"
    }
  }
}
