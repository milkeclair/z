z.cls.draw SyntaxBox
  z.cls.attr value default=initial

  z.cls.fn run access=write
    false || $self.value.set "value:$1" || return 1
    $self.value.get || return 1
    print -r -- "$REPLY" | cat >/dev/null
    cat <<'TEXT' >/dev/null
z.cls.fn.done
TEXT
    $self.value.get || return 1
    return 9
  z.cls.fn.done

z.cls.drew
