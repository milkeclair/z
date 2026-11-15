# write a project registration while preserving existing entries
#
# $name: validated project name
# $dir: normalized absolute project directory
# REPLY: null
# return: 0|1
#
# example:
#  z.pj.add._write name=example dir=/repo/example
z.pj.add._write() {
  z.arg.named.literal name "$@" && local name=$REPLY
  z.arg.named.literal dir "$@" && local dir=$REPLY
  z.pj.file._path "$name" || return 1
  local file=$REPLY

  if [[ -e $file || -L $file ]]; then
    z.io.error "Project is already registered: $name"
    return 1
  fi

  z.pj.file._root
  local registry=$REPLY
  if z.dir.not.exists "$registry"; then
    z.dir.make path="$registry" || return 1
  fi

  z.file.write.literal path="$file" content="$dir"$'\n' overwrite=false
}
