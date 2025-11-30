z.git.user() {
  shift
  if z.git.user._is_set_opt "$1"; then
    shift
    z.git.user._set "$@"
  else
    z.git.user._show
  fi
}

z.git.user._show() {
  echo "--- local user info ---"
  local_user_name=$(command git config --local user.name)
  local_user_email=$(command git config --local user.email)
  echo "user.name: $local_user_name"
  echo "user.email: $local_user_email"
  echo ""
  echo "--- global user info ---"
  global_user_name=$(command git config --global user.name)
  global_user_email=$(command git config --global user.email)
  echo "user.name: $global_user_name"
  echo "user.email: $global_user_email"
}

z.git.user._is_set_opt() {
  if [[ $1 = --set ]]; then
    return 0
  else
    return 1
  fi
}

z.git.user._set() {
  echo "--- set local user info ---"
  if [[ -z $1 && -z $2 ]]; then
    echo "require user.name"
    echo "require user.email"
    return 1
  elif [[ -z $1 ]]; then
    echo "require user.name"
    return 1
  elif [[ -z $2 ]]; then
    echo "require user.email"
    return 1
  fi

  command git config --local user.name "$1"
  command git config --local user.email "$2"
  echo "set user.name: $1"
  echo "set user.email: $2"
}
