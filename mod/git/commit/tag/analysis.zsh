# 有効なコミットタグの一覧
#
# REPLY: 有効なコミットタグの配列
# return: null
#
# example:
#   z.git.commit._tag.list #=> ("feat" "fix" "chore" "docs" "style" "refactor" "test")
z.git.commit._tag.list() {
  local tags=(
    feat
    fix
    chore
    docs
    style
    refactor
    test
  )

  REPLY=("${tags[@]}")
}
