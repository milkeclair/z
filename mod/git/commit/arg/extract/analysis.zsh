z.git.commit.arg.extract.opts() {
  local -A args=(${(@)@})
  local opts=()

  local idx=1
  while z.int.is.lteq $idx ${args[opts_count]:-0}; do
    opts+=(${args[opts_$idx]})
    ((idx++))
  done

  z.return ${opts[@]}
}
