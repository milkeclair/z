z.git.commit._show_help() {
  z.io "Usage: z.git c [tag] message ?[ticket] ?[-nt|-ca|-ae]"
}

z.git.commit.tdd._show_help() {
  z.io.empty
  z.io.indent level=1 "Usage:"
  z.io.indent level=2 "red:      git red [tag] message ?[ticket] ?[-nt|-ca]"
  z.io.indent level=2 "green:    git green [tag] message ?[ticket] ?[-nt|-ca]"
  z.io.indent level=2 "refactor: git green refactor message ?[ticket] ?[-nt|-ca]"
}

z.git.commit.tdd._show_tag_help() {
  local tags=($@)

  z.io.empty
  z.io.indent level=1 "Valid tags are:"
  z.io.indent level=2 "${tags[*]}"
}

z.git.commit._show_committer() {
  z.io.empty
  z.io "--- committer ---"
  z.io "name: $(git config --local user.name)"
  z.io "email: $(git config --local user.email)"
}
