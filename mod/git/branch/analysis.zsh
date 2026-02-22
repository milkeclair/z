z.git.branch.current() {
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    z.return $(command git branch --show-current)
  else
    z.return
  fi
}

z.git.branch.merged() {
  local result=$(command git branch --merged)
  local no_checkout=$(echo "$result" | grep -v '^[*+]')
  local trimmed=$(echo "$no_checkout" | sed 's/^[[:space:]]*//')

  z.return $trimmed
}
