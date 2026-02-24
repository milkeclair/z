z.git.hp.arg.has.origin() {
  for arg in "$@"; do
    if z.is.eq "$arg" "origin"; then
      return 0
    fi
  done
  return 1
}

z.git.hp.arg.has.develop() {
  for arg in "$@"; do
    if z.is.eq "$arg" "dev" || z.is.eq "$arg" "develop"; then
      return 0
    fi
  done
  return 1
}
