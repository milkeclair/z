# display git user info (name and email) for both local and global configurations
#
# REPLY: null
# return: null
#
# example:
#   z.git.user
#   #=> --- local user info ---
#   #   user.name: milkeclair
#   #   user.email: milkeclair@example.com...
z.git.user() {
  z.git.user.local
  z.io.line
  z.git.user.global
}

# display local git user info (name and email)
#
# REPLY: null
# return: null
#
# example:
#   z.git.user.local
#   #=> user.name: milkeclair
#   #   user.email: milkeclair@example.com
z.git.user.local() {
  z.io "--- local user info ---"
  local user_name=$(git config --local user.name)
  local user_email=$(git config --local user.email)
  z.io "user.name: $user_name"
  z.io "user.email: $user_email"
}

# display global git user info (name and email)
#
# REPLY: null
# return: null
#
# example:
#   z.git.user.global
#   #=> user.name: milkeclair
#   #   user.email: milkeclair@example.com
z.git.user.global() {
  z.io "--- global user info ---"
  local user_name=$(git config --global user.name)
  local user_email=$(git config --global user.email)
  z.io "user.name: $user_name"
  z.io "user.email: $user_email"
}
