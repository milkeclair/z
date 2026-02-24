z.git.user.set.required() {
  if z.is.null $1 && z.is.null $2; then
    z.io "require user.name"
    z.io "require user.email"
    return 1
  elif z.is.null $1; then
    z.io "require user.name"
    return 1
  elif z.is.null $2; then
    z.io "require user.email"
    return 1
  fi
}
