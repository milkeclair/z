# 連想配列に指定したキーがあるか確認する
#
# $key: 確認するキー
# $1: 連想配列名
# REPLY: null
# return: 0\1
#
# example:
#  local -A hash=(name "John")
#  z.hash.has.key hash key=name
#  # return: 0
z.hash.has.key() {
  z.arg.named.shift key $@ && local hash_name=$REPLY
  z.arg.named key $@ && local key=$REPLY

  local ref="${hash_name}[$key]"

  (( ${(P)+ref} ))
}

# 連想配列の指定したキーに値があるか確認する
#
# $key: 確認するキー
# $1: 連想配列名
# REPLY: null
# return: 0\1
#
# example:
#  local -A hash=(name "John")
#  z.hash.has.value hash key=name
#  # return: 0
z.hash.has.value() {
  z.arg.named key $@ && local key=$REPLY
  z.arg.named.shift key $@ && local hash_name=$REPLY

  z.is.not.null ${${(P)hash_name}[$key]}
}
