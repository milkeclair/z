# open a registered project in Visual Studio Code
#
# $1: project name
# REPLY: null
# return: code exit status, or 1 for invalid input or a missing project
#
# example:
#  z.pj some_project
z.pj() {
  z.arr.count "$@"
  if z.int.is.not.eq $REPLY 1; then
    z.io.error "Usage: z.pj <name>"
    return 1
  fi

  z.pj.file._directory "$1" || return 1
  local dir=$REPLY
  if z.dir.not.exists "$dir"; then
    z.io.error "Project directory does not exist: $dir"
    return 1
  fi
  if ! z.io.null whence code; then
    z.io.error "Visual Studio Code command is not available: code"
    return 1
  fi

  REPLY=""
  code "$dir"
}

# register a project directory without overwriting an existing name
#
# $name: project name
# $dir: existing project directory
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.add name=some_project dir=~/repo/p/some
z.pj.add() {
  z.arg.named.literal name "$@" && local name=$REPLY
  z.arg.named.literal dir "$@" && local dir=$REPLY

  z.pj.add._directory "$dir" || return 1
  local project_dir=$REPLY
  z.pj.add._write name="$name" dir="$project_dir" || return 1

  z.io.literal "Registered: $name -> $project_dir"
  REPLY=""
}

# list registered project names and directories
#
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.list
z.pj.list() {
  z.pj.file._names
  local names=("${(@)REPLY}")
  z.arr.count "${names[@]}"
  if z.int.is.zero $REPLY; then
    z.io "No projects registered."
    REPLY=""
    return 0
  fi

  local name
  for name in "${names[@]}"; do
    z.pj.file._directory "$name" || return 1
    z.io.literal "$name"$'\t'"$REPLY"
  done
  REPLY=""
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
  z.arr.count "$@" && local arg_count=$REPLY
  if z.int.is.gt $arg_count 1; then
    z.io.error "Usage: z.pj.remove [name]"
    return 1
  fi

  local name=$1
  if z.int.is.zero $arg_count; then
    z.pj.remove._select || return 1
    name=$REPLY
    z.is.null "$name" && return 0
  fi

  z.pj.remove._entry "$name" || return 1
  z.io "Removed: $name"
  REPLY=""
}
