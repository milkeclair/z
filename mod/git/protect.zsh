_protected_branch_file="${HOME}/.zsh/protected_branches.txt"

if [[ ! -f "$_protected_branch_file" ]]; then
  command mkdir -p "$(dirname "$_protected_branch_file")"
  command touch "$_protected_branch_file"
fi

z.git.protect() {
  # $1であるprotectはブランチではないので、保護対象から外す
  shift
  for arg in "$@"; do
    # 一致する行が無い場合
    # x: 行全体一致 q: 結果を出力しない
    if ! grep -xq "$arg" "$_protected_branch_file"; then
      echo "$arg" >>"$_protected_branch_file"
      echo "ブランチを保護しました: $arg"
    else
      echo "このブランチはすでに保護されています: $arg"
    fi
  done
}

z.git.protect.remove() {
  shift
  for arg in "$@"; do
    if grep -xq "$arg" "$_protected_branch_file"; then
      if [ $(wc -l <"$_protected_branch_file") -gt 1 ]; then
        grep -v "^$arg$" "$_protected_branch_file" >"temp.txt" &&
          mv "temp.txt" "$_protected_branch_file"
      else
        grep -v "^$arg$" "$_protected_branch_file" >"$_protected_branch_file"
      fi
      echo "ブランチの保護を解除しました"
    else
      echo "このブランチは保護されていません"
    fi
  done
}

z.git.protect.list() {
  z.git.protect._all
  local protected_branches=("${REPLY[@]}")

  echo "保護されているブランチの一覧"
  # インデックスにアクセスするためにkフラグを使用
  local index=1
  for branch in "${(@k)protected_branches[@]}"; do
    # 連番: ブランチ名
    printf "%d: %s\n" "$index" "$branch"
    index=$((index + 1))
  done
}

z.git.protect.is_protected() {
  z.git.protect._all
  local protected_branches=("${REPLY[@]}")

  for arg in "$@"; do
    for branch in "${protected_branches[@]}"; do
      if [[ $arg == "$branch" ]]; then
        return 0
      fi
    done
  done

  return 1
}

z.git.protect._all() {
  local protected_branch=()

  while IFS= read -r line; do
    protected_branch+=("$line")
  done <"$_protected_branch_file"

  REPLY=("${protected_branch[@]}")
}
