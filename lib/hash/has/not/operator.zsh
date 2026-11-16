# 連想配列に指定したキーがないか確認する
#
# $key: 確認するキー
# $1: 連想配列名
# REPLY: null
# return: 0\1
#
# example:
#   local -A hash
#   hash[name]="John"
#   z.hash.has.not.key hash key=age
#   echo $?  # outputs 0
z.hash.has.not.key() {
  z.arg.named.shift key $@ && local hash_name=$REPLY
  z.arg.named key $@ && local key=$REPLY

  local ref="${hash_name}[$key]"

  (( ! ${(P)+ref} ))
}

# 連想配列の指定したキーに値がないか確認する
#
# $key: 確認するキー
# $1: 連想配列名
# REPLY: null
# return: 0\1
#
# example:
#   local -A hash
#   hash[name]=""
#   z.hash.has.not.value hash key=name
#   echo $?  # outputs 0
z.hash.has.not.value() {
  z.arg.named key $@ && local key=$REPLY
  z.arg.named.shift key $@ && local hash_name=$REPLY

  z.is.null ${${(P)hash_name}[$key]}
}
