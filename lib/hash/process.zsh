# convert a hash to an array of "key:value" strings
#
# $1: name of the hash
# REPLY: array of "key:value" strings
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

  z.return ${arr[@]}
}

# merge two hashes into one
#
# $base: name of the base hash
# $other: name of the other hash
# REPLY: array of key-value pairs (key1 value1 key2 value2 ...)
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

  z.return.hash merged_hash
}
