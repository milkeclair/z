for set_file in ${z_root}/mod/git/user/set/*.zsh; do
  source $set_file
done

for show_file in ${z_root}/mod/git/user/show/*.zsh; do
  source $show_file
done

z.git.user() {
  z.arg.first $@ && local first_arg=$REPLY
  z.is.eq $first_arg "user" && shift

  if z.git.user.opt.is.set "$1"; then
    z.git.user.set "$2"
  else
    z.git.user.show
  fi
}

z.git.user.show() {
  z.git.user.show.info.local
  z.io.line
  z.git.user.show.info.global
}

z.git.user.set() {
  z.io "--- set local user info ---"
  z.git.user.set.required "$1" "$2" || return 1

  command git config --local user.name "$1"
  command git config --local user.email "$2"
  z.io "set user.name: $1"
  z.io "set user.email: $2"
}
