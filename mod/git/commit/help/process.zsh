z.git.commit.help.committer() {
  z.io.line
  z.io "--- committer ---"
  z.io "name: $(command git config --local user.name)"
  z.io "email: $(command git config --local user.email)"
}
