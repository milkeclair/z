# download one branch archive into an existing work directory
#
# $dir: work directory
# $branch?: branch name (default: main)
# REPLY: archive file path
# return: 0|1
#
# example:
#  z.update.archive._download dir=/tmp/update branch=main
z.update.archive._download() {
  z.arg.named dir "$@"
  local dir=$REPLY
  z.dir.exists "$dir" || { REPLY=""; return 1; }

  z.arg.named branch "$@" default=main
  local branch=$REPLY

  local file="$dir/source.tar.gz"
  z.file.exists "$file" && { REPLY=""; return 1; }

  local url="https://github.com/milkeclair/z/archive/refs/heads/$branch.tar.gz"
  if ! curl -fLsS "$url" -o "$file"; then
    rm -f "$file"
    REPLY=""
    return 1
  fi

  REPLY="$file"
}

# extract a branch archive into a new directory
#
# $file: archive file
# $dir: new extraction directory
# REPLY: extracted source directory
# return: 0|1
#
# example:
#  z.update.archive._extract file=/tmp/source.tar.gz dir=/tmp/update/source
z.update.archive._extract() {
  z.arg.named file "$@"

  local file=$REPLY

  z.arg.named dir "$@"
  local dir=$REPLY
  z.is.null "$dir" && { REPLY=""; return 1; }

  z.dir.exists "$dir" && { REPLY=""; return 1; }

  z.dir.make path="$dir" || return 1

  if ! tar -xzf "$file" -C "$dir"; then
    z.dir.remove path="$dir"
    REPLY=""
    return 1
  fi

  local roots=("$dir"/*(N/))
  if ! z.int.is.eq ${#roots} 1; then
    z.dir.remove path="$dir"
    REPLY=""
    return 1
  fi

  REPLY="$roots[1]"
}
