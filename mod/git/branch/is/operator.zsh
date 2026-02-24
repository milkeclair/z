for not_file in ${z_root}/mod/git/branch/is/not/*.zsh; do
  source $not_file
done

z.git.branch.is.exists() {
  local branch=$1

  command git show-ref --verify --quiet "refs/heads/$branch"
}
