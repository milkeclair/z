z.cls.draw TestCounter; {
  z.cls.attr count 0
  z.cls.attr label default

  z.cls.fn increment
    (( ++count ))
    REPLY=$count
  z.cls.fn.done

  z.cls.fn value
    REPLY=$count
  z.cls.fn.done

  z.cls.fn add
    (( count += $1 ))
    REPLY=$count
  z.cls.fn.done

  z.cls.fn twice
    "$1.increment"
    "$1.increment"
  z.cls.fn.done

  z.cls.fn fail
    (( ++count ))
    REPLY="failure:$1"
    return 7
  z.cls.fn.done

  z.cls.fn loop
    for item in one two; do
      label+=":$item"
    done
    if z.str.start_with "$label" default:; then
      REPLY=$label
    fi
  z.cls.fn.done

  z.cls.drew
}
