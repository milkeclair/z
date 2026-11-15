z.cls.draw SyntaxBox; {
  z.cls.attr value initial

  z.cls.fn run
    false || value="value:$1"
    print -r -- "$value" | cat >/dev/null
    cat <<'TEXT' >/dev/null
z.cls.fn.done
TEXT
    REPLY=$value
    return 9
  z.cls.fn.done

  z.cls.drew
}
