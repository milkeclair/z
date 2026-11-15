# get the project registry directory
#
# REPLY: registry directory path
# return: 0
#
# example:
#  z.pj._root
z.pj._root() {
  local config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  z.return "$config_home/z/pj"
}

# get a validated project registration file path
#
# $1: project name
# REPLY: registration file path, or empty on failure
# return: 0 for a valid name, otherwise 1
#
# example:
#  z.pj._file some_project
z.pj._file() {
  local name=$1
  if ! z.pj._valid_name "$name"; then
    z.io.error "Invalid project name: $name"
    z.return
    return 1
  fi

  z.pj._root
  z.return "$REPLY/$name"
}

# get registered project names in alphabetical order
#
# REPLY: array of project names
# return: 0
#
# example:
#  z.pj._names
z.pj._names() {
  z.pj._root
  local registry=$REPLY
  local -a names=()
  local file
  for file in "$registry"/*(N.); do
    z.pj._valid_name "${file:t}" && names+=("${file:t}")
  done
  REPLY=("${(@o)names}")
}

# read a registered absolute directory as data
#
# $1: project name
# REPLY: registered directory, or empty on failure
# return: 0 if the registration can be read, otherwise 1
#
# example:
#  z.pj._directory some_project
z.pj._directory() {
  z.pj._file "$1" || return 1
  local file=$REPLY
  if [[ ! -f $file || -L $file ]]; then
    z.io.error "Project is not registered: $1"
    z.return
    return 1
  fi

  z.file.read path="$file" || { z.return; return 1; }
  local dir=$REPLY
  if [[ $dir != /* || $dir == *$'\n'* ]]; then
    z.io.error "Invalid project registration: $1"
    z.return
    return 1
  fi
  z.return "$dir"
}
