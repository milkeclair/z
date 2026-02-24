z.git.user.show.info.local() {
  z.io "--- local user info ---"
  local_user_name=$(command git config --local user.name)
  local_user_email=$(command git config --local user.email)
  z.io "user.name: $local_user_name"
  z.io "user.email: $local_user_email"
}

z.git.user.show.info.global() {
  z.io "--- global user info ---"
  global_user_name=$(command git config --global user.name)
  global_user_email=$(command git config --global user.email)
  z.io "user.name: $global_user_name"
  z.io "user.email: $global_user_email"
}
