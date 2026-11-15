# get the project registry directory
#
# REPLY: registry directory path
# return: null
#
# example:
#  z.pj.file._root
z.pj.file._root() {
  local config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  z.return "$config_home/z/pj"
}

# get a validated project registration file path
#
# $1: project name
# REPLY: registration file path, or empty on failure
# return: 0|1
#
# example:
#  z.pj.file._path some_project
z.pj.file._path() {
  local name=$1
  if ! z.pj.name.is.valid "$name"; then
    z.io.error "Invalid project name: $name"
    z.return
    return 1
  fi

  z.pj.file._root
  z.return "$REPLY/$name"
}

# get registered project names in filename order
#
# REPLY: array of project names
# return: null
#
# example:
#  z.pj.file._names
z.pj.file._names() {
  z.pj.file._root
  local registry=$REPLY
  local names=()
  local file
  for file in "$registry"/*(N.); do
    local name=${file:t}
    z.pj.name.is.valid "$name" && names+=("$name")
  done

  REPLY=("${names[@]}")
}

# read the directory stored in a project registration
#
# $1: project name
# REPLY: registered directory, or empty on failure
# return: 0|1
#
# example:
#  z.pj.file._directory some_project
z.pj.file._directory() {
  z.pj.file._path "$1" || return 1
  local file=$REPLY
  if ! z.pj.file.is.registration "$file"; then
    z.io.error "Project is not registered: $1"
    z.return
    return 1
  fi

  z.file.read path="$file" || { z.return; return 1; }
  local dir=$REPLY
  if ! z.str.start_with "$dir" / || z.str.includes "$dir" $'\n'; then
    z.io.error "Invalid project registration: $1"
    z.return
    return 1
  fi

  z.return "$dir"
}
