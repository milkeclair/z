# determine if a hash does not have a given key
#
# $key: key to check
# $1: name of the hash
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

# determine if a hash does not have a value for a given key
#
# $key: key to check
# $1: name of the hash
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
