z.git.stats() {
  z.io.line
  z.io "--- author stats ---"
  z.git.stats.show $@
}

z.git.stats.show() {
  z.git.stats.exclude.exts $@ && local exclude_exts=($REPLY)
  z.git.stats.exclude.dirs $@ && local exclude_dirs=($REPLY)

  z.git.stats.exclude $@
  z.git.stats.author $@
}

z.git.stats.exclude() {
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  z.io.line "exclude_exts: ${exclude_exts[*]}" "exclude_dirs: ${exclude_dirs[*]}"
  z.io.line
}

z.git.stats.author() {
  z.git.stats.author.header
  z.git.stats.author.body $@
  z.git.stats.author.footer
}
