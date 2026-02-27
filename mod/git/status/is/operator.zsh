z.git.status.is.dirty() {
  z.is.not.null "$(command git status --porcelain)"
}
