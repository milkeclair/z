# get all author names from git log
#
# REPLY: array of author names
# return: null
#
# example:
#   z.git.stats.author.names #=> ("Alice" "Bob" "Charlie")
z.git.stats.author.names() {
  local author_name="%an"
  local strip_regex="^[[:space:]]*//;s/[[:space:]]*$"
  local names=$(git log --format=$author_name |
    sed "s/$strip_regex//" |
    sort |
    uniq)

  local authors=()
  while IFS= read -r name; do
    authors+=($name)
  done <<< $names

  z.return $authors
}
