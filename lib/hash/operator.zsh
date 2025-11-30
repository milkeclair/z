# determine if a hash has a given key
#
# $key: key to check
# $1: name of the hash
# REPLY: null
# return: 0\1
#
# example:
#   local -A hash
#   hash[name]="John"
#   z.hash.has_key hash key=name
#   echo $?  # outputs 0
z.hash.has_key() {
  z.arg.named.shift key $@ && local hash_name=$REPLY
  z.arg.named key $@ && local key=$REPLY

  local ref="${hash_name}[$key]"

  (( ${(P)+ref} ))
}

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
#   z.hash.has_not_key hash key=age
#   echo $?  # outputs 0
z.hash.has_not_key() {
  z.arg.named.shift key $@ && local hash_name=$REPLY
  z.arg.named key $@ && local key=$REPLY

  local ref="${hash_name}[$key]"

  (( ! ${(P)+ref} ))
}

# determine if a hash has a value for a given key
#
# $key: key to check
# $1: name of the hash
# REPLY: null
# return: 0\1
#
# example:
#   local -A hash
#   hash[name]="John"
#   z.hash.has_value hash key=name
#   echo $?  # outputs 0
z.hash.has_value() {
  z.arg.named key $@ && local key=$REPLY
  z.arg.named.shift key $@ && local hash_name=$REPLY

  z.is_not_null ${${(P)hash_name}[$key]}
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
#   z.hash.has_not_value hash key=name
#   echo $?  # outputs 0
z.hash.has_not_value() {
  z.arg.named key $@ && local key=$REPLY
  z.arg.named.shift key $@ && local hash_name=$REPLY

  z.is_null ${${(P)hash_name}[$key]}
}
