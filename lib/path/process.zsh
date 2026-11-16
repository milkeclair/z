# ファイルパスのディレクトリ部分を取得する
#
# $1: ファイルのパス
# REPLY: ディレクトリのパス
# return: null
#
# example:
#  z.path.dir "/usr/local/bin/script.sh"
#  # REPLY: "/usr/local/bin"
z.path.dir() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:h}
}

# ファイルパスのベース名を取得する
#
# $1: ファイルのパス
# REPLY: ベース名
# return: null
#
# example:
#  z.path.base "/usr/local/bin/script.sh"
#  # REPLY: "script.sh"
z.path.base() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:t}
}

# ファイルパスから拡張子を除いたベース名を取得する
#
# $1: ファイルのパス
# REPLY: 拡張子を除いたベース名
# return: null
#
# example:
#  z.path.stem "/usr/local/bin/script.sh"
#  # REPLY: "script"
z.path.stem() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  local base=${filepath:t}
  REPLY=${base:r}
}

# ファイルパスの拡張子を取得する
#
# $1: ファイルのパス
# REPLY: 拡張子
# return: null
#
# example:
#  z.path.ext "/usr/local/bin/script.sh"
#  # REPLY: "sh"
z.path.ext() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  local base=${filepath:t}
  REPLY=${base:e}
}

# 実パスを取得する（絶対パスにし、シンボリックリンクを解決する）
#
# $1: ファイルのパス
# REPLY: 実パス
# return: null
#
# example:
#  # /tmp/z-exampleにscript.shがあり、シンボリックリンクを含まない場合
#  # カレントディレクトリは/tmp/z-example
#  z.path.real "./script.sh"
#  # REPLY: "/tmp/z-example/script.sh"
z.path.real() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:A}
}

# 絶対パスを取得する
#
# $1: ファイルのパス
# REPLY: 絶対パス
# return: null
#
# example:
#  # カレントディレクトリが/tmp/z-exampleの場合
#  z.path.abs "./script.sh"
#  # REPLY: "/tmp/z-example/script.sh"
z.path.abs() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:a}
}

# パスを小文字に変換する
#
# $1: ファイルのパス
# REPLY: 小文字のパス
# return: null
#
# example:
#  z.path.downcase "/UsR/LoCaL/Bin/ScRiPt.Sh"
#  # REPLY: "/usr/local/bin/script.sh"
z.path.downcase() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:l}
}

# パスを大文字に変換する
#
# $1: ファイルのパス
# REPLY: 大文字のパス
# return: null
#
# example:
#  z.path.upcase "/UsR/LoCaL/Bin/ScRiPt.Sh"
#  # REPLY: "/USR/LOCAL/BIN/SCRIPT.SH"
z.path.upcase() {
  local filepath=$1

  z.str.is.not.path_like "$filepath" && REPLY="" && return

  REPLY=${filepath:u}
}
