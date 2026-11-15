# open a registered project in Visual Studio Code
#
# $1: project name
# REPLY: null
# return: code exit status, or 1 for invalid input or a missing project
#
# example:
#  z.pj some_project
z.pj() {
  if [[ $# -ne 1 ]]; then
    z.io.error "Usage: z.pj <name>"
    return 1
  fi

  z.pj._directory "$1" || return 1
  local dir=$REPLY
  if [[ ! -d $dir ]]; then
    z.io.error "Project directory does not exist: $dir"
    return 1
  fi
  if ! whence code >/dev/null 2>&1; then
    z.io.error "Visual Studio Code command is not available: code"
    return 1
  fi

  z.return
  code "$dir"
}

# register a project directory without overwriting an existing name
#
# $name: project name
# $dir: existing project directory
# REPLY: null
# return: 0 if registered, otherwise 1
#
# example:
#  z.pj.add name=some_project dir=~/repo/p/some
z.pj.add() {
  z.pj.add._value name "$@" && local name=$REPLY
  z.pj.add._value dir "$@" && local dir=$REPLY
  z.pj._file "$name" || return 1
  local file=$REPLY

  case $dir in
    '~') dir=$HOME ;;
    '~/'*) dir="$HOME/${dir#\~/}" ;;
  esac
  if [[ -z $dir || $dir == *$'\n'* || ! -d $dir ]]; then
    z.io.error "Project directory does not exist or is invalid: $dir"
    return 1
  fi
  dir=${dir:A}
  if [[ -e $file || -L $file ]]; then
    z.io.error "Project is already registered: $name"
    return 1
  fi

  [[ -d ${file:h} ]] || z.dir.make path="${file:h}" || return 1
  if ! (setopt noclobber; print -r -- "$dir" > "$file"); then
    z.io.error "Could not register project: $name"
    return 1
  fi
  printf 'Registered: %s -> %s\n' "$name" "$dir"
  z.return
}

# list registered project names and directories
#
# REPLY: null
# return: 0 if listed, otherwise 1
#
# example:
#  z.pj.list
z.pj.list() {
  z.pj._names
  local -a names=("${REPLY[@]}")
  if [[ ${#names} -eq 0 ]]; then
    z.io "No projects registered."
    z.return
    return 0
  fi

  local name
  for name in "${names[@]}"; do
    z.pj._directory "$name" || return 1
    printf '%s\t%s\n' "$name" "$REPLY"
  done
  z.return
}

# remove a project registration by name or numbered selection
#
# $1?: project name; when omitted, select from registered names
# REPLY: null
# return: 0 if removed or cancelled, otherwise 1
#
# example:
#  z.pj.remove some_project
#  z.pj.remove
z.pj.remove() {
  if [[ $# -gt 1 ]]; then
    z.io.error "Usage: z.pj.remove [name]"
    return 1
  fi
  local name=${1:-}
  if [[ -z $name && $# -eq 0 ]]; then
    z.pj.remove._select || return 1
    name=$REPLY
    [[ -z $name ]] && return 0
  fi

  z.pj._file "$name" || return 1
  local file=$REPLY
  if [[ ! -f $file || -L $file ]]; then
    z.io.error "Project is not registered: $name"
    return 1
  fi
  rm -- "$file" || return 1
  z.io "Removed: $name"
  z.return
}
