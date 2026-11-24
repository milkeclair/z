z.cls.draw TypedState
  z.cls.attr table default=initial
  z.cls.attr number default=0
  z.cls.attr fraction default=0
  z.cls.attr values default=initial
  z.cls.attr missing default=initial
  z.cls.attr plain default=initial

  z.cls.fn fill
    $self.table.set "space key" "value words" empty "" || return 1
    $self.number.set 255 || return 1
    $self.fraction.set 1.23456789 || return 1
    $self.values.set one one two || return 1
    $self.plain.set $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)'
  z.cls.fn.done

  z.cls.fn verify
    $self.table.get || return 1
    local table_values=("${REPLY[@]}")
    z.int.is.eq "${#table_values}" 2 || return 1
    $self.number.get || return 1
    (( REPLY == 255 )) || return 1
    $self.fraction.get || return 1
    (( REPLY == 1.23456789 )) || return 1
    $self.values.get || return 1
    local list=("${REPLY[@]}")
    z.int.is.eq "${#list}" 2 || return 1
    z.is.eq "$list[1]" one || return 1
    z.is.eq "$list[2]" two || return 1
    $self.plain.get || return 1
    z.is.eq "$REPLY" $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)' || return 1
    REPLY=preserved
  z.cls.fn.done

z.cls.drew
