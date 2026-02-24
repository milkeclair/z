for not_file in ${z_root}/mod/git/commit/arg/is/not/*.zsh; do
  source $not_file
done

z.git.commit.arg.is.enough() {
  local tag_and_message=2

  z.arr.count $@
  if z.int.is.lt $REPLY $tag_and_message; then
    z.io.line
    z.git.commit.help
    return 1
  fi
}
