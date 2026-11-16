# キャッシュのソース行から関数名を取り出す
#
# $1: ソース行
# $2?: 先頭の空白を取り除いたソース行
# REPLY: 関数名|null
# return: 0|1
#
# example:
#  z.completion.cache.build.line._function_name "z.example() {"
#  # REPLY: "z.example"
#  # return: 0
z.completion.cache.build.line._function_name() {
  local line=$1
  local trimmed_line=${2-$line}
  if z.int.is.lt $# 2; then
    z.str.gsub str="$line" search="^[[:space:]]+" replace=""
    trimmed_line=$REPLY
  fi
  z.str.is.match "$trimmed_line" '^z[.].*\(\)' || return 1

  z.str.partition "$trimmed_line" "()" literal=true
  local -a declaration=("${(@)REPLY}")
  local function_name=$declaration[1]
  local declaration_suffix=$declaration[2]

  z.str.gsub str="$declaration_suffix" search="^[[:space:]]+" replace=""
  declaration_suffix=$REPLY
  z.is.eq "$declaration_suffix" "{" || return 1

  REPLY="$function_name"
}
