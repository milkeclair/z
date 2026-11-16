# Gitのログから作成者名をすべて取得する
#
# REPLY: 作成者名の配列
# return: null
#
# example:
#  # コミットの作成者がAlice、Bob、Charlieだけの場合
#  z.git.stats._author.names
#  # REPLY: ("Alice" "Bob" "Charlie")
z.git.stats._author.names() {
  local author_name="%an"
  local strip_regex="^[[:space:]]*//;s/[[:space:]]*$"
  local names=$(git log --format=$author_name |
    sed "s/$strip_regex//" |
    sort |
    uniq)

  local authors=()
  while IFS= read -r name; do
    authors+=("$name")
  done <<< "$names"

  REPLY=("${authors[@]}")
}
