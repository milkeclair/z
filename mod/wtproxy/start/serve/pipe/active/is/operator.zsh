# check if the current active path matches a pipe active path
#
# $1: pipe active worktree path
# REPLY: null
# return: 0 if active path matches, otherwise 1
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

    local state_active_path=${active_line#active }
    state_active_path=${(Q)state_active_path}
    z.is.eq "$state_active_path" "$active_path"
    return
  fi

  z.wtproxy._entry.active || return 1
  local -A active_entry=("${(@)REPLY}")
  z.is.eq "$active_entry[path]" "$active_path"
}
