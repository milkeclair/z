z.git.push() {
  if ! z.git.hp.has_origin "$@"; then
    local current_branch
    current_branch=$(z.git.hp.current_branch)

    if [[ $current_branch =~ ^pr/([0-9]+)$ ]]; then
      local pr_number=${match[1]}
      printf "%s\n\n" "PR #${pr_number}の最新にpushします"
      command git push origin "HEAD:refs/pull/${pr_number}/head"
      z.status
      return $REPLY
    fi

    printf "%s\n\n" "ブランチが指定されていないため、現在のブランチにpushします"
    if ! z.git.protect.is_protected "$current_branch"; then
      # $(function)で関数の戻り値を文字列として取得する
      command git push --set-upstream origin "$current_branch"
    else
      echo "このブランチは保護されています"
      echo "pushを実行するには、保護を解除してください"
    fi
  elif z.git.protect.is_protected "$@"; then
    echo "このブランチは保護されています"
    echo "pushを実行するには、保護を解除してください"
  fi
}
