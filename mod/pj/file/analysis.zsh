# プロジェクトの登録ディレクトリを取得する
#
# REPLY: 登録先ディレクトリのパス
# return: null
#
# example:
#  local XDG_CONFIG_HOME=/tmp/config
#  z.pj.file._root
#  # REPLY: "/tmp/config/z/pj"
z.pj.file._root() {
  local config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  REPLY="$config_home/z/pj"
}

# 検証済みのプロジェクト登録ファイルのパスを取得する
#
# $1: プロジェクト名
# REPLY: 登録ファイルのパス。失敗時は空
# return: 0|1
#
# example:
#  local XDG_CONFIG_HOME=/tmp/config
#  z.pj.file._path some_project
#  # REPLY: "/tmp/config/z/pj/some_project"
#  # return: 0
z.pj.file._path() {
  local name=$1
  if ! z.pj.name.is.valid "$name"; then
    z.io.error "Invalid project name: $name"
    REPLY=""
    return 1
  fi

  z.pj.file._root
  REPLY="$REPLY/$name"
}

# ファイル名順に登録済みのプロジェクト名を取得する
#
# REPLY: プロジェクト名の配列
# return: null
#
# example:
#  # firstとsecondの有効な登録ファイルがある場合
#  z.pj.file._names
#  # REPLY: ("first" "second")
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

# プロジェクト登録に保存されたディレクトリを読む
#
# $1: プロジェクト名
# REPLY: 登録されたディレクトリ。失敗時は空
# return: 0|1
#
# example:
#  # some_projectの登録先が/tmp/exampleの場合
#  z.pj.file._directory some_project
#  # REPLY: "/tmp/example"
#  # return: 0
z.pj.file._directory() {
  z.pj.file._path "$1" || return 1
  local file=$REPLY
  if ! z.pj.file.is.registration "$file"; then
    z.io.error "Project is not registered: $1"
    REPLY=""
    return 1
  fi

  z.file.read path="$file" || { REPLY=""; return 1; }
  local dir=$REPLY
  if ! z.str.start_with "$dir" / || z.str.includes "$dir" $'\n'; then
    z.io.error "Invalid project registration: $1"
    REPLY=""
    return 1
  fi

  REPLY="$dir"
}
