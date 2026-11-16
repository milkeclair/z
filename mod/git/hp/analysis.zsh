# 現在のブランチ名からチケット番号を取り出す
#
# REPLY: チケット番号。見つからなければ空文字列
# return: null
#
# example:
#  # カレントブランチがfeature/some-description-123の場合
#  z.git._hp.ticket
#  # REPLY: "123"
z.git._hp.ticket() {
  z.git.branch.current._get && local branch=$REPLY

  # 例: feature/some-description-123 => some-description-123
  z.str.split str=$branch delimiter="/"
  local branch_parts=(${(@)REPLY})
  local after_last_slash=$branch_parts[-1]

  # 例: some-description-123 => some description 123
  z.str.split str=$after_last_slash delimiter="-"
  local parts=(${(@)REPLY})
  local first_part=$parts[1]
  local last_part=$parts[-1]

  if z.int.is.match $last_part; then
    REPLY=$last_part
  elif z.int.is.match $first_part; then
    REPLY=$first_part
  else
    REPLY=""
  fi
}
