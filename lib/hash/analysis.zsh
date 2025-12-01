# get the keys of a hash
#
# $1: name of the hash
# REPLY: array of keys
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#   z.hash.keys hash
#   echo $REPLY  # outputs ("name" "age")
z.hash.keys() {
  local hash_name=$1

  z.return ${(Pk)hash_name}
}

# get the values of a hash
#
# $1: name of the hash
# REPLY: array of values
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#   z.hash.values hash
#   echo $REPLY  # outputs ("John" "30")
z.hash.values() {
  local hash_name=$1

  z.return ${(Pv)hash_name}
}

# get the entries of a hash as key-value pairs
#
# $1: name of the hash
# REPLY: array of key-value pairs
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#   z.hash.entries hash
#   echo $REPLY  # outputs ("name" "John" "age" "30")
z.hash.entries() {
  local hash_name=$1

  z.return ${(Pkv)hash_name}
}

# count the number of entries in a hash
#
# $1: name of the hash
# REPLY: number of entries
# return: null
#
# example:
#   local -A hash
#   hash[name]="John"
#   hash[age]="30"
#   z.hash.count hash
#   echo $REPLY  # outputs 2
z.hash.count() {
  local hash_name=$1
  local -A hash_ref=(${(Pkv)hash_name})

  z.return ${#hash_ref}
}
