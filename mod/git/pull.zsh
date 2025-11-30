z.git.pull() {
  shift
  if ! z.git.hp.has_origin "$@"; then
    if z.git.hp.has_develop "$@"; then
      printf "%s\n\n" "developブランチをpullします"
      command git pull origin develop
    else
      local current_branch=$(z.git.hp.current_branch)

      if [[ $current_branch =~ ^pr/([0-9]+)$ ]]; then
        local pr_number=${match[1]}
        printf "%s\n\n" "PR #${pr_number}の最新をpullします"
        command git pull origin pull/"$pr_number"/head:"$current_branch"
      else
        printf "%s\n\n" "ブランチが指定されていないため、現在のブランチをpullします"
        command git pull origin "$current_branch"
      fi
    fi
  else
    command git pull "$@"
  fi
}
