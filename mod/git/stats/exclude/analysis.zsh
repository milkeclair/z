z.git.stats.exclude.exts() {
  z.arg.named exclude_exts $@ && local exts=($REPLY)
  if z.is.null $REPLY; then
    exts=(
      html
      css
    )
  fi

  z.return $exts
}

z.git.stats.exclude.dirs() {
  z.arg.named exclude_dirs $@ && local dirs=($REPLY)
  if z.is.null $REPLY; then
    dirs=(
      node_modules
    )
  fi

  z.return $dirs
}
