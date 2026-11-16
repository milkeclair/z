# 指定した値を真として扱うか確認する
# 真として扱う値:
#   - true または 0
#   - パスの形式ではない空でない文字列
#   - 存在するディレクトリのパス
#   - 存在するファイルのパス
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.truthy "true" #=> 0
#  z.is.truthy 0 #=> 0
#  z.is.truthy "/path/to/existing/dir" #=> 0
#  z.is.truthy "/path/to/existing/file" #=> 0
#  z.is.truthy "some string" #=> 0
#
#  z.is.truthy #=> 1
#  z.is.truthy "" #=> 1
#  z.is.truthy "false" #=> 1
#  z.is.truthy 1 #=> 1
#  z.is.truthy "/path/to/non-existing/dir" #=> 1
#  z.is.truthy "/path/to/non-existing/file" #=> 1
z.is.truthy() {
  local value=$1

  z.guard; {
    z.is.false $value && return 1
  }

  z.is.true $value && return 0
  z.dir.exists $value && return 0
  z.file.exists $value && return 0
  z.str.is.path_like $value && return 1

  z.is.not.null $value && return 0

  return 1
}

# 指定した値を偽として扱うか確認する
# 偽として扱う値:
#   - false または 1
#   - null（空文字列）
#   - 存在しないディレクトリのパス
#   - 存在しないファイルのパス
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.falsy #=> 0
#  z.is.falsy "false" #=> 0
#  z.is.falsy 1 #=> 0
#  z.is.falsy "" #=> 0
#  z.is.falsy "/path/to/non-existing/dir" #=> 0
#  z.is.falsy "/path/to/non-existing/file" #=> 0
#
#  z.is.falsy "true" #=> 1
#  z.is.falsy 0 #=> 1
#  z.is.falsy "some string" #=> 1
#  z.is.falsy "/path/to/existing/dir" #=> 1
#  z.is.falsy "/path/to/existing/file" #=> 1
z.is.falsy() {
  local value=$1

  z.guard; {
    z.is.true $value && return 1
  }

  z.is.false $value && return 0
  z.is.null $value && return 0

  z.str.is.path_like $value &&
  z.dir.not.exists $value &&
  z.file.not.exists $value &&
    return 0

  return 1
}

# 指定した値がtrueか確認する
# trueとして扱う値:
#   - true または 0
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.true true #=> 0
#  z.is.true 0 #=> 0
#
#  z.is.true false #=> 1
#  z.is.true 1 #=> 1
#  z.is.true "some string" #=> 1
#  z.is.true "" #=> 1
z.is.true() {
  local value=$1

  z.is.eq $value true && return 0
  z.is.eq $value 0 && return 0

  return 1
}

# 指定した値がfalseか確認する
# falseとして扱う値:
#   - false または 1
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.false false #=> 0
#  z.is.false 1 #=> 0
#
#  z.is.false true #=> 1
#  z.is.false 0 #=> 1
#  z.is.false "some string" #=> 1
#  z.is.false "" #=> 1
z.is.false() {
  local value=$1

  z.is.eq $value false && return 0
  z.is.eq $value 1 && return 0

  return 1
}

# 2つの値が等しいか確認する
#
# $1: 基準値
# $2: 比較する値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.eq "a" "a" #=> 0
#  z.is.eq 1 1 #=> 0
#  z.is.eq "" "" #=> 0
z.is.eq() {
  local base=$1
  local other=$2

  [[ $base == $other ]]
}

# 指定した値がnullか確認する
#
# $1: 値
# REPLY: null
# return: 0|1
#
# example:
#  z.is.null "" #=> 0
#  z.is.null #=> 0
z.is.null() {
  local value=$1

  [[ -z $value ]]
}
