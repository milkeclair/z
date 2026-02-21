z.git.commit.help.committer() {
  z.io.line
  z.io "--- committer ---"
  z.io "name: $(git config --local user.name)"
  z.io "email: $(git config --local user.email)"
}
