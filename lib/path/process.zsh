# get the directory part of a file path
#
# $1: file path
# REPLY: directory path
# return: null
#
# example:
#   z.path.dir "/usr/local/bin/script.sh"
#   echo $REPLY  # outputs "/usr/local/bin"
z.path.dir() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.return ${filepath:h}
}

# get the base name of a file path
#
# $1: file path
# REPLY: base name
# return: null
#
# example:
#   z.path.base "/usr/local/bin/script.sh"
#   echo $REPLY  # outputs "script.sh"
z.path.base() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.return ${filepath:t}
}

# get the stem (base name without extension) of a file path
#
# $1: file path
# REPLY: stem
# return: null
#
# example:
#   z.path.stem "/usr/local/bin/script.sh"
#   echo $REPLY  # outputs "script"
z.path.stem() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  local base=${filepath:t}
  z.return ${base:r}
}

# get the extension of a file path
#
# $1: file path
# REPLY: extension
# return: null
#
# example:
#   z.path.ext "/usr/local/bin/script.sh"
#   echo $REPLY  # outputs "sh"
z.path.ext() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  local base=${filepath:t}
  z.return ${base:e}
}

# get the real (absolute and symlink-resolved) path
#
# $1: file path
# REPLY: real path
# return: null
#
# example:
#   z.path.real "./script.sh"
#   echo $REPLY  # outputs "/home/user/current/script.sh"
z.path.real() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.path.abs $filepath
  local absolute=$REPLY

  while [[ -L $absolute ]]; do
    local target=$(readlink $absolute)
    if z.str.is.not.match $target "/*"; then
      z.path.dir $absolute
      target=$REPLY/$target
    fi
    z.path.abs $target
    absolute=$REPLY
  done

  z.return $absolute
}

# get the absolute path
#
# $1: file path
# REPLY: absolute path
# return: null
#
# example:
#   z.path.abs "./script.sh"
#   echo $REPLY  # outputs "/home/user/current/script.sh"
z.path.abs() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.return ${filepath:a}
}

# convert path to lowercase
#
# $1: file path
# REPLY: lowercase path
# return: null
#
# example:
#   z.path.downcase "/UsR/LoCaL/Bin/ScRiPt.Sh"
#   echo $REPLY  # outputs "/usr/local/bin/script.sh"
z.path.downcase() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.return ${filepath:l}
}

# convert path to uppercase
#
# $1: file path
# REPLY: uppercase path
# return: null
#
# example:
#   z.path.upcase "/UsR/LoCaL/Bin/ScRiPt.Sh"
#   echo $REPLY  # outputs "/USR/LOCAL/BIN/SCRIPT.SH"
z.path.upcase() {
  local filepath=$1

  z.str.is.not.path_like $filepath && z.return "" && return

  z.return ${filepath:u}
}
