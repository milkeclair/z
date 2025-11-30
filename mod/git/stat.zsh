z.git.stat() {
  echo ""
  echo "--- author stats ---"
  z.git.stat._author
}

z.git.stat._author() {
  # example: ("html" "css")
  exclude_exts=()
  # example: ('node_modules')
  exclude_dirs=("node_modules")
  echo -e "exclude_exts: ${exclude_exts[*]}\nexclude_dirs: ${exclude_dirs[*]}\n"

  # 22, 12, 12, 12, 12
  echo "┌──────────────────────┬────────────┬────────────┬────────────┬────────────┐"
  echo "│ author               │ commit     │ add        │ delete     │ total      │"
  echo "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
  z.git.stat._each_authors
  echo "└──────────────────────┴────────────┴────────────┴────────────┴────────────┘"
}

z.git.stat._each_authors() {
  local authors=()
  while IFS= read -r author; do
    authors+=("$author")
  done < <(z.git.stat._author_names)

  local valid_authors=()
  local previous_commits=0
  local previous_lines=(0 0)
  local index=1

  local author_commit_map=()
  for i in {1..${#authors[@]}}; do
    local idx=$((i-1))
    local author="${authors[$idx]}"
    local commits=$(z.git.stat._commit_details "$author")
    local commit_count=$(z.git.stat._commit_count "$author")

    if [[ $commit_count -ne 0 ]]; then
      author_commit_map+=("$author:$commits:$commit_count")
    fi
  done

  for entry in "${author_commit_map[@]}"; do
    local author="${entry%%:*}"      # a:b:c => a
    local rest="${entry#*:}"         # a:b:c => b:c
    local commit_count="${rest##*:}" # b:c => c
    local commits="${rest%:*}"       # b:c => b

    local inserted=$(echo "$commits" | awk '{print $1}')
    local deleted=$(echo "$commits" | awk '{print $2}')
    local total=$(z.git.stat._sum "$inserted" "$deleted")

    # commit_count, (inserted, deleted) == previous_commits, previous_lines
    if z.git.stat._is_previous_author "$previous_commits" "$commit_count" "$previous_lines" "$commits"; then
      # remove duplicate author from authors
      valid_authors=("${valid_authors[@]/$author/}")
      continue
    fi

    # example: author_name commit: 100 add: 1000 delete: 1000 total: 2000
    z.git.stat._show_author "$author" "$commit_count" "$inserted" "$deleted" "$total"

    if [[ ${#valid_authors[@]} != $index && ${#valid_authors[@]} != 1 && $index -ne ${#author_commit_map[@]} ]]; then
      echo "├──────────────────────┼────────────┼────────────┼────────────┼────────────┤"
    fi

    # setup for next
    previous_commits=$commit_count
    previous_lines=($commits)
    index=$((index + 1))
  done
}

z.git.stat._show_author() {
  local red='\033[0;31m'
  local green='\033[0;32m'
  local orange='\033[0;33m'
  local purple='\033[0;35m'
  local cyan='\033[0;36m'
  local creset='\033[0m'
  local author=$1
  local commit_count=$2
  local inserted=$3
  local deleted=$4
  local total=$5

  if [[ -z $author ]]; then
    author="Everyone"
  fi

  # %-20s: ljust 20 for string
  # %-10d: ljust 5 for digit
  # example: │ author_name │ commit: 100 │ add: 1000 │ delete: 1000 │ total: 2000 │
  printf "│ %-20s │ ${orange}%-10d${creset} │ ${green}%-10d${creset} │ ${red}%-10d${creset} │ ${purple}%-10d${creset} │\n" "$author" "$commit_count" "$inserted" "$deleted" "$total"
}

z.git.stat._sum() {
  local inserted=$1; local deleted=$2
  awk -v inserted="$inserted" -v deleted="$deleted" 'BEGIN {print inserted + deleted}'
}

z.git.stat._author_names() {
  local author_name='%an'
  local strip_regex='^[[:space:]]*//;s/[[:space:]]*$'
  git log --format="$author_name" |
    sed "s/$strip_regex//" |
    sort |
    uniq
}


z.git.stat._commit_count() {
  local authors=$1
  # wc -l: count lines
  git log --oneline --author="$authors" |
    grep -v "Merge branch\|Merge pull request" | \
    wc -l
}

z.git.stat._commit_details() {
  local authors=$1
  # grep -v -E: exclude files with specific extensions
  # example: \.(html|css)$
  local exclude_exts_pattern="\.($(IFS=\|; echo "${exclude_exts[*]}"))$"
  # example: /(node_modules|dist)/
  local exclude_dirs_pattern="($(IFS=\|; echo "${exclude_dirs[*]}"))/"

  git log --pretty=tformat: --numstat --author="$authors" |
    grep -v -E "$exclude_exts_pattern|$exclude_dirs_pattern" |
    awk '{inserted+=$1; deleted+=$2} END {print inserted, deleted}'
}

z.git.stat._is_previous_author() {
  local previous_commits=$1
  local commit_count=$2
  local previous_lines=($3)
  local commits=($4)
  # commit_count, (inserted, deleted) == previous_commits, previous_lines
  if [[ $previous_commits == $commit_count && "${previous_lines[@]}" == "${commits[@]}" ]]; then
    return 0
  else
    return 1
  fi
}
