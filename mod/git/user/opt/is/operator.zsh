z.git.user.opt.is.set() {
  if z.is.eq "$1" "--set"; then
    return 0
  else
    return 1
  fi
}
