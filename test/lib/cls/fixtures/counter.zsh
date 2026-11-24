z.cls.draw TestCounter
  z.cls.attr count default=0
  z.cls.attr label default=default

  z.cls.fn increment
    $self.count.get || return 1
    $self.count.set "$(( REPLY + 1 ))" || return 1
    $self.count.get
  z.cls.fn.done

  z.cls.fn value
    $self.count.get
  z.cls.fn.done

  z.cls.fn add
    z.arg.named count "$@" && local count=$REPLY
    z.int.is.match "$count" || return 1
    $self.count.get || return 1
    $self.count.set "$(( REPLY + count ))" || return 1
    $self.count.get
  z.cls.fn.done

  z.cls.fn twice
    $self.increment || return 1
    $self.increment
  z.cls.fn.done

  z.cls.fn fail
    $self.increment || return 1
    REPLY="failure:$1"
    return 7
  z.cls.fn.done

  z.cls.fn loop
    $self.label.get || return 1
    local label=$REPLY
    for item in one two; do
      label+=":$item"
    done
    if z.str.start_with "$label" default:; then
      $self.label.set "$label" || return 1
      $self.label.get
    fi
  z.cls.fn.done

z.cls.drew
