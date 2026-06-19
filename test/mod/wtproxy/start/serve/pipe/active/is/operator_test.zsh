source ${z_main}

z.t.describe "z.wtproxy.start._serve.pipe.active.is.current"; {
  z.t.context "state fileのactive pathが同じ場合"; {
    z.t.it "active entryを読まずにtrueを返す"; {
      local state_file=/tmp/z_t/wtproxy_pipe_active_is_current_same/state
      local calls=/tmp/z_t/wtproxy_pipe_active_is_current_same/calls
      z.dir.make path=${state_file:h}
      z.file.write path=$state_file content="active \"/tmp/worktree\""
      z.file.write path=$calls content=""
      z_wtproxy_serve_state_file=$state_file
      z.t.mock name="z.wtproxy._entry.active" behavior="
        print -r -- active >> /tmp/z_t/wtproxy_pipe_active_is_current_same/calls
        return 1
      "

      z.wtproxy.start._serve.pipe.active.is.current /tmp/worktree

      z.t.expect.status.is.true skip_unmock=true
      z.file.read path=$calls
      z.t.expect.reply "" skip_unmock=true
      z_wtproxy_serve_state_file=""
    }
  }

  z.t.context "state fileのactive pathが違う場合"; {
    z.t.it "falseを返す"; {
      local state_file=/tmp/z_t/wtproxy_pipe_active_is_current_changed/state
      z.dir.make path=${state_file:h}
      z.file.write path=$state_file content="active \"/tmp/other-worktree\""
      z_wtproxy_serve_state_file=$state_file

      z.wtproxy.start._serve.pipe.active.is.current /tmp/worktree

      z.t.expect.status.is.false
      z_wtproxy_serve_state_file=""
    }
  }

  z.t.context "state fileがない場合"; {
    z.t.it "active entryで判定する"; {
      z_wtproxy_serve_state_file=""
      z.t.mock name="z.wtproxy._entry.active" behavior="
        local -A entry=(path /tmp/worktree)
        z.return.hash entry
      "

      z.wtproxy.start._serve.pipe.active.is.current /tmp/worktree

      z.t.expect.status.is.true
    }
  }
}
