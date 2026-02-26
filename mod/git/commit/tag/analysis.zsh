# list of valid commit tags
#
# REPLY: array of valid commit tags
# return: null
#
# example:
#   z.git.commit.tag.list #=> ("feat" "fix" "chore" "docs" "style" "refactor" "test")
z.git.commit.tag.list() {
  local tags=(
    feat
    fix
    chore
    docs
    style
    refactor
    test
  )

  z.return $tags
}
