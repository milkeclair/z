z.cls.draw SyntaxBox
  z.cls.attr value default=initial

  z.cls.method run
    false || $self.value.set "value:$1" || return 1
    $self.value.get || return 1
    print -r -- "$REPLY" | cat >/dev/null
    cat <<'TEXT' >/dev/null
z.cls.method.defined
TEXT
    $self.value.get || return 1
    return 9
  z.cls.method.defined
z.cls.drew
