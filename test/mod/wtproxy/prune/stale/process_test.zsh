source ${z_main}

z.t.describe "z.wtproxy.prune._stale.locked"; {
  z.t.context "存在しないworktree pathがある場合"; {
    z.t.it "Docker resourceを削除してからstale entryを削除する"; {
      local alive=/tmp/z_t/wtproxy_prune/alive
      local stale=/tmp/z_t/wtproxy_prune/stale
      z.dir.make path=$alive
      z.t.mock name="z.wtproxy._state.load" behavior="
        z.wtproxy._state.init
        z_wtproxy_state_active_path=$stale
        z_wtproxy_state_paths=($alive $stale)
        z_wtproxy_state_compose[$alive]=project_alive
        z_wtproxy_state_compose[$stale]=project_stale
      "
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 0"
      z.t.mock name="z.wtproxy._state.save" behavior="return 0"

      z.wtproxy.prune._stale.locked
      local -A result=("${(@)REPLY}")

      z.t.expect "$result[entries_count]" 1
      z.t.expect "$result[pruned_projects]" project_stale
      z.t.expect "$z_wtproxy_state_active_path" ""
      z.t.expect "${z_wtproxy_state_paths[*]}" "$alive"
    }
  }

  z.t.context "Docker resource削除に失敗した場合"; {
    z.t.it "stateを削除せずfalseを返す"; {
      local alive=/tmp/z_t/wtproxy_prune/alive_failure
      local stale=/tmp/z_t/wtproxy_prune/stale_failure
      z.dir.make path=$alive
      z.t.mock name="z.wtproxy._state.load" behavior="
        z.wtproxy._state.init
        z_wtproxy_state_active_path=$stale
        z_wtproxy_state_paths=($alive $stale)
        z_wtproxy_state_compose[$alive]=project_alive
        z_wtproxy_state_compose[$stale]=project_stale
      "
      z.t.mock name="z.wtproxy._docker.prune" behavior="return 1"
      z.t.mock name="z.wtproxy._state.save" behavior="return 0"

      z.wtproxy.prune._stale.locked

      z.t.expect.status.is.false
      z.t.expect "$z_wtproxy_state_active_path" "$stale"
      z.t.expect "${z_wtproxy_state_paths[*]}" "$alive $stale"
      z.t.expect "$z_wtproxy_state_compose[$stale]" project_stale
    }
  }
}
