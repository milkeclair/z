z.cls.draw TypedState
  z.cls.attr table default=initial
  z.cls.attr number default=0
  z.cls.attr fraction default=0
  z.cls.attr values default=initial
  z.cls.attr missing default=initial
  z.cls.attr plain default=initial

  z.cls.fn fill
    unset table
    typeset -gA table=("space key" "value words" empty "")
    typeset -gi 16 number=255
    typeset -gF 8 fraction=1.23456789
    typeset -gU values=(one one two)
    unset missing
    plain=$'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)'
  z.cls.fn.done

  z.cls.fn verify
    [[ ${table[space key]} == "value words" && ${table[empty]} == "" ]] || return 1
    (( ${+table[empty]} && ${#table} == 2 )) || return 1
    (( number == 255 )) || return 1
    [[ $number == 16#* && ${(t)number} == integer* ]] || return 1
    (( fraction == 1.23456789 )) || return 1
    [[ ${(t)fraction} == float* ]] || return 1
    [[ ${#values} == 2 && $values[1] == one && $values[2] == two && ${(t)values} == *unique* ]] || return 1
    (( ${+missing} == 0 )) || return 1
    [[ $plain == $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)' ]] || return 1
    REPLY=preserved
  z.cls.fn.done

z.cls.drew
