z.git.hp.ticket() {
  local branch=$(z.git.b.current)

  # e.g. feature/some-description-123 => some-description-123
  z.str.split str="$current_branch" delimiter="/"
  local branch_parts=(${(@)REPLY})
  local after_last_slash=$branch_parts[-1]

  # e.g. some-description-123 => some description 123
  z.str.split str="$after_last_slash" delimiter="-"
  local parts=(${(@)REPLY})
  local first_part=$parts[1]
  local last_part=$parts[-1]

  if z.str.is.match $last_part "^[0-9]+$"; then
    z.return $last_part
  elif z.str.is.match $first_part "^[0-9]+$"; then
    z.return $first_part
  else
    z.return ""
  fi
}
