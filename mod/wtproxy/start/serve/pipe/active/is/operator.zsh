# 現在の有効なパスが中継先の有効なパスと一致するか確認する
#
# $1: 中継で有効なworktreeのパス
# REPLY: null
# return: 有効なパスが一致する場合は0、それ以外は1
#
# example:
#  z.wtproxy.start._serve.pipe.active.is.current /tmp/worktree
z.wtproxy.start._serve.pipe.active.is.current() {
  local active_path=$1

  z.is.null "$active_path" && return 1

  if z.is.not.null "$z_wtproxy_serve_state_file"; then
    z.file.exists "$z_wtproxy_serve_state_file" || return 1

    local active_line=""
    IFS= read -r active_line < "$z_wtproxy_serve_state_file"
    z.is.not.null "$active_line" || return 1

    z.str.remove.prefix "$active_line" "active "
    local state_active_path=$REPLY
    state_active_path=${(Q)state_active_path}
    z.is.eq "$state_active_path" "$active_path"
    return
  fi

  z.wtproxy._entry.active || return 1
  local -A active_entry=("${(@)REPLY}")
  z.is.eq "$active_entry[path]" "$active_path"
}
