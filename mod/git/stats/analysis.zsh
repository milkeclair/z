for author_file in ${z_root}/mod/git/stats/author/*.zsh; do
  source $author_file
done

for commit_file in ${z_root}/mod/git/stats/commit/*.zsh; do
  source $commit_file
done

for exclude_file in ${z_root}/mod/git/stats/exclude/*.zsh; do
  source $exclude_file
done
