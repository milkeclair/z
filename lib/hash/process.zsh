# 連想配列を"key:value"形式の文字列の配列へ変換する
#
# $1: 連想配列名
# REPLY: "key:value"形式の文字列の配列
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#   z.hash.to_arr hash
#   echo $REPLY  # outputs ("name:John" "age:30")
z.hash.to_arr() {
  local hash_name=$1
  local arr=()

  for key in ${(Pk)hash_name}; do
    arr+=("$key:${${(P)hash_name}[$key]}")
  done

  REPLY=("${arr[@]}")
}

# 2つの連想配列を1つに統合する
#
# $base: 基準の連想配列名
# $other: 比較する連想配列名
# REPLY: キーと値の組の配列（key1 value1 key2 value2 ...）
# return: null
#
# example:
#   local -A hash1
#   hash1[name]="John"
#   local -A hash2
#   hash2[age]="30"
#   
#   z.hash.merge base=hash1 other=hash2
#   local -A merged=($REPLY)
#   echo ${merged[name]}  # outputs "John"
z.hash.merge() {
  z.arg.named base $@ && local base=$REPLY
  z.arg.named other $@ && local other=$REPLY

  local -A merged_hash

  for key in ${(Pk)base}; do
    local ref="${base}[$key]"
    merged_hash[$key]=${(P)ref}
  done

  for key in ${(Pk)other}; do
    local ref="${other}[$key]"
    merged_hash[$key]=${(P)ref}
  done

  z.hash.entries merged_hash
}
