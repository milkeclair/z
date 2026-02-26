# show commit help
#
# REPLY: null
# return: null
#
# example:
#   z.git.commit.help
#   #=> name: Alice
#   #   email: alice@example.com
z.git.commit.help.committer() {
  z.io.line
  z.io "--- committer ---"
  z.io "name: $(command git config --local user.name)"
  z.io "email: $(command git config --local user.email)"
}
