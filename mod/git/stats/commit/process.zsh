# 作成者の一覧に対してコミット統計を処理する
#
# $authors: 作成者名の配列
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: コミット情報の配列（各要素は"author:details:commit_count"形式）
# return: null
#
# example:
#   z.git.stats._commit.map authors=("Alice" "Bob") exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
#   #=> REPLY=("Alice:1000 500:50" "Bob:800 300:40")
z.git.stats._commit.map() {
  z.arg.named authors $@ && local authors_raw=$REPLY
  z.arg.named exclude_exts $@ && local exclude_exts=($REPLY)
  z.arg.named exclude_dirs $@ && local exclude_dirs=($REPLY)

  local authors=()
  if z.is.not.null "$authors_raw"; then
    z.str.split str="$authors_raw" delimiter=" "
    authors=($REPLY)
  fi

  local commit_map=()

  for author in ${authors[@]}; do
    z.git.stats._commit.details author="$author" exclude_exts=$exclude_exts exclude_dirs=$exclude_dirs
    z.str.split str="$REPLY" delimiter=" "
    local details=($REPLY)
    z.git.stats._commit.count "$author" && local count=$REPLY

    if z.int.is.not.zero $count; then
      local details_str="${details[1]} ${details[2]}"
      commit_map+=("$author:$details_str:$count")
    fi
  done

  REPLY=("${commit_map[@]}")
}

# 追加行数と削除行数を合計して変更行数を求める
#
# $author: 作成者名
# $exclude_exts?: 除外する拡張子の配列（例: "md" "txt"）
# $exclude_dirs?: 除外するディレクトリの配列（例: "docs" "tests"）
# REPLY: 作成者の変更行数の合計
# return: null
#
# example:
#   z.git.stats._commit.details author="milkeclair" exclude_exts=("md" "txt") exclude_dirs=("docs" "tests")
z.git.stats._commit.details() {
  z.arg.named author $@ && local author=$REPLY
  z.arg.named exclude_exts $@ && local exclude_exts_raw=$REPLY
  z.arg.named exclude_dirs $@ && local exclude_dirs_raw=$REPLY

  z.git.stats._commit.details.excludes exclude_exts=$exclude_exts_raw exclude_dirs=$exclude_dirs_raw
  z.arr.split "$REPLY" && local patterns=($REPLY)
  local exclude_exts_pattern=$patterns[1]
  local exclude_dirs_pattern=$patterns[2]

  local inserted_total=0 && local deleted_total=0
  local log=$(
    git log --pretty=tformat: --numstat --author="$author" |
      grep -v -E "$exclude_exts_pattern|$exclude_dirs_pattern"
  )

  while read -r inserted deleted _file; do
    z.is.null "$inserted" && z.is.null "$deleted" && continue

    z.is.eq "$inserted" "-" && inserted=0
    z.is.eq "$deleted" "-" && deleted=0
    inserted_total=$((inserted_total + inserted))
    deleted_total=$((deleted_total + deleted))
  done <<< "$log"

  REPLY="$inserted_total $deleted_total"
}

# 変更行数を数える
#
# $inserted: 追加行数
# $deleted: 削除行数
# REPLY: 変更行数の合計
# return: null
#
# example:
#   z.git.stats._commit.sum_lines inserted=1000 deleted=500
#   #=> 1500
z.git.stats._commit.sum_lines() {
  z.arg.named inserted $@ && local inserted=$REPLY
  z.arg.named deleted $@ && local deleted=$REPLY

  z.is.null "$inserted" && inserted=0
  z.is.null "$deleted" && deleted=0
  local result=$((inserted + deleted))

  REPLY=$result
}
