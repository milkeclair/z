# determine if a hash has a given key
#
# $1: name of the hash
# $2: key to check
# REPLY: null
# return: 0\1
#
# example:
#   local -A hash
#   hash[name]="John"
#   z.hash.has_key hash name
#   echo $?  # outputs 0
z.hash.has_key() {
  local hash_name=$1
  local key=$2

  z.is_not_null ${${(P)hash_name}[$key]}
}
