z.git.hp.show_current() {
  echo "現在のブランチ: $(z.git.hp.current_branch)"
}

z.git.hp.current_branch() {
  if command git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    command git branch --show-current
  else
    echo ""
  fi
}

z.git.hp.is_force() {
  for arg in "$@"; do
    if [[ $arg = -f || $arg = --force || $arg = --force-with-lease ]]; then
      return 0
    fi
  done
  return 1
}

z.git.hp.has_origin() {
  for arg in "$@"; do
    if [[ $arg = origin ]]; then
      return 0
    fi
  done
  return 1
}

z.git.hp.has_develop() {
  for arg in "$@"; do
    if [[ $arg = dev ]]; then
      return 0
    fi
  done
  return 1
}
