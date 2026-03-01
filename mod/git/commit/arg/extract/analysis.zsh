# extract commit args
#
# $@: commit args
# REPLY: array of commit options
# return: null
#
# example:
#   z.git.commit.arg.extract.opts (opts_count=3 opts_1="-m" opts_2="commit message" opts_3="--amend")
#   #=> ("-m" "commit message" "--amend")
z.git.commit.arg.extract.opts() {
  local -A args=("${(@)@}")
  local opts=()

  local idx=1
  while z.int.is.lteq $idx ${args[opts_count]:-0}; do
    opts+=(${args[opts_$idx]})
    ((idx++))
  done

  z.return $opts
}
