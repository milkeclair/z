z.git.worktree.to() {
  local open_vscode=true
  local branch=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        z.git.worktree.to._print_help
        return 0
        ;;
      -no|--no-open)
        open_vscode=false
        shift
        ;;
      -*)
        z.io.error "Unknown option: $1"
        return 1
        ;;
      *)
        branch=$1
        shift
        ;;
    esac
  done

  if z.str.empty $branch; then
    z.git.worktree.to._print_help >&2
    return 1
  fi

  local root=$(git worktree list --porcelain | grep '^worktree ' | head -1 | cut -d' ' -f2)
  local tree_root="$root/../${$(basename "$root")}_worktree"
  local branch_path=${branch//\//_}

  if z.eq $branch "root"; then
    if z.is_true $open_vscode; then
      code $root
    else
      cd $root
    fi
    return 0
  fi

  local normalized_path=$(cd "$tree_root/$branch_path" 2>/dev/null && pwd)

  if z.dir.exist $tree_root/$branch_path; then
    if git worktree list --porcelain | grep -qF "worktree $normalized_path"; then
      if z.is_true $open_vscode; then
        code "$tree_root/$branch_path"
      else
        cd "$tree_root/$branch_path"
      fi
      return 0
    else
      z.io.error "Error: Directory exists but is not registered as a worktree"
      z.io.error "Please remove the directory or use a different branch name: $tree_root/$branch_path"
      return 1
    fi
  fi

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    command git worktree add "$tree_root/$branch_path" $branch
  else
    command git worktree add -b $branch "$tree_root/$branch_path"
  fi

  local config_file="$root/.worktreeconfig"
  if z.file.exist $config_file; then
    cp "$config_file" "$tree_root/$branch_path/.worktreeconfig"

    local section=""
    local script_lines=()

    while IFS= read -r line; do
      z.str.empty $line || [[ "$line" =~ ^[[:space:]]*# ]] && continue

      if [[ "$line" =~ '^\[([^]]+)\]' ]]; then
        section=${line#\[}
        section=${section%\]}
        continue
      fi

      if z.eq $section "file"; then
        if z.file.exist "$root/$line"; then
          local dest_dir=$(dirname "$tree_root/$branch_path/$line")
          z.dir.make path="$dest_dir"
          cp "$root/$line" "$tree_root/$branch_path/$line"
        elif [[ -d "$root/$line" ]]; then
          z.dir.make path="$tree_root/$branch_path/$line"
          cp -a "$root/$line/." "$tree_root/$branch_path/$line/"
        fi
      elif z.eq $section "script"; then
        script_lines+=("$line")
      fi
    done < "$config_file"

    if z.int.gt ${#script_lines[@]} 0; then
      (
        cd "$tree_root/$branch_path"
        for cmd in "${script_lines[@]}"; do
          eval "$cmd"
        done
      )
    fi
  fi

  if z.is_true $open_vscode; then
    code "$tree_root/$branch_path"
  else
    cd "$tree_root/$branch_path"
  fi
}

z.git.worktree.to._print_help() {
  z.io "Usage: git.worktree.to [-no] <branch|root>"
  z.io "  -no   stay in current shell without launching VS Code"
  z.io "  root  return to the root worktree"
  z.io "  <branch>  create or reuse a worktree for the branch"
}

z.git.worktree.pr() {
  local pr_number=$1

  if z.str.empty $pr_number; then
    z.io.error "Please specify a PR number"
    return 1
  fi

  local branch="pr/$pr_number"

  command git fetch origin pull/"$pr_number"/head:"$branch"
  z.git.worktree.to $branch
}

z.git.worktree.dev() {
  local branch="develop"

  z.git.worktree.to root
  command git fetch
  command git pull origin $branch
}

z.git.worktree.list() {
  local root=$(git worktree list --porcelain | grep '^worktree ' | head -1 | cut -d' ' -f2)
  local tree_root="$root/../${$(basename "$root")}_worktree"

  local worktree="" branch="" head=""
  local -a registered_worktrees

  while IFS= read -r line; do
    if z.str.start_with $line "worktree "; then
      z.str.not_empty $worktree && z.git.worktree.list._print_worktree_entry
      worktree=${line#worktree }
      registered_worktrees+=("$worktree")
    elif z.str.start_with $line "HEAD "; then
      head=${line#HEAD }
    elif z.str.start_with $line "branch "; then
      branch=${line#branch refs/heads/}
    elif z.str.empty $line; then
      z.git.worktree.list._print_worktree_entry
      worktree="" branch="" head=""
    fi
  done < <(git worktree list --porcelain)

  z.str.not_empty $worktree && z.git.worktree.list._print_worktree_entry

  for dir in $tree_root/*(/N); do
    local normalized_dir=$(cd "$dir" && pwd)
    local is_registered=false

    for registered in "${registered_worktrees[@]}"; do
      if z.eq $normalized_dir $registered; then
        is_registered=true && break
      fi
    done

    if z.eq $is_registered false; then
      local dir_name=$(basename "$dir")
      z.str.color.red "$dir_name [unregistered]"
      z.io $REPLY
    fi
  done
}

z.git.worktree.list._print_worktree_entry() {
  local short_hash=${head:0:7}

  if z.eq $worktree $root; then
    z.str.color.magenta "root $short_hash [$branch]"
    z.io $REPLY
  else
    z.io "$branch $short_hash"
  fi
}

z.git.worktree.pt() {
  local current_worktree=$(git rev-parse --show-toplevel 2>/dev/null)
  export CURRENT_BRANCH=$(z.git.hp.current_branch)
  export CURRENT_WORKTREE=$current_worktree
  z.io.error "Current branch saved as: $CURRENT_BRANCH"
}

z.git.worktree.bk() {
  if z.str.empty $CURRENT_WORKTREE; then
    z.io.error "No current worktree saved. Use 'git pt' to save the current worktree first."
    return 1
  fi

  if z.dir.not_exist $CURRENT_WORKTREE; then
    z.io.error "Saved worktree no longer exists: $CURRENT_WORKTREE"
    return 1
  fi

  cd $CURRENT_WORKTREE
}

z.git.worktree.cb() {
  local current_worktree=$(git rev-parse --show-toplevel 2>/dev/null)
  local merged_branches=($(git branch --merged | grep -v "\*" | sed 's/^[[:space:]]*//'))

  git worktree list --porcelain | while IFS= read -r line; do
    if z.str.start_with $line "worktree "; then
      worktree_path=${line#worktree }
    elif z.str.start_with $line "branch "; then
      branch_ref=${line#branch }
      branch_name=${branch_ref#refs/heads/}

      local is_protected=false
      if z.git.protect.is_protected $branch_name; then
        is_protected=true
      fi

      z.eq $worktree_path $current_worktree && continue

      if z.eq $is_protected false && [[ " ${merged_branches[*]} " == *" $branch_name "* ]]; then
        z.git.worktree.rm $branch_name
      else
        z.io "Skipping branch: $branch_name"
      fi
    fi
  done

  command git worktree prune
}

z.git.worktree.rm() {
  local unregistered=false
  local branch=""

  while [[ $# -gt 0 ]]; do
    case $1 in
      -un|--unregistered)
        unregistered=true
        shift
        ;;
      -*)
        z.io.error "Unknown option: $1"
        return 1
        ;;
      *)
        branch=$1
        shift
        ;;
    esac
  done

  if z.is_true $unregistered; then
    z.git.worktree.rm._remove_unregistered
    z.status
    return $REPLY
  fi

  if z.str.empty $branch; then
    z.io.error "Please specify a branch name"
    return 1
  fi

  local root=$(git worktree list --porcelain | grep '^worktree ' | head -1 | cut -d' ' -f2)
  local tree_root="$root/../${$(basename "$root")}_worktree"
  local branch_path=${branch//\//_}
  local normalized_path=$(cd "$tree_root/$branch_path" 2>/dev/null && pwd)

  local worktree_dir=""
  local actual_branch=""

  while IFS= read -r line; do
    if z.str.start_with $line "worktree "; then
      local current_worktree=${line#worktree }
      if z.eq $current_worktree $normalized_path; then
        worktree_dir=$current_worktree
      fi
    elif z.str.start_with $line "branch " && z.str.not_empty $worktree_dir; then
      local branch_ref=${line#branch }
      actual_branch=${branch_ref#refs/heads/}
      break
    fi
  done < <(git worktree list --porcelain)

  if z.str.empty $worktree_dir; then
    z.io.error "Worktree not found for the specified branch: $branch"
    git worktree list
    return 1
  fi

  if z.str.empty $actual_branch; then
    z.io.error "Failed to retrieve branch information for the worktree"
    return 1
  fi

  if z.git.protect.is_protected $actual_branch; then
    z.io.error "This branch is protected: $actual_branch"
    return 1
  fi

  local removal_completed=false
  local -a removal_notes

  if command git worktree remove -f $worktree_dir; then
    removal_completed=true
  else
    removal_notes+=("Failed to remove worktree: $worktree_dir")

    chmod -R u+w "$worktree_dir" 2>/dev/null || true

  if command git worktree remove -f $worktree_dir 2>/dev/null; then
      removal_completed=true
    else
      if z.git.worktree.rm._is_registered $worktree_dir; then
        removal_notes+=("Still failed. Forced removal could not detach the worktree: $worktree_dir")
        removal_notes+=("Please remove it manually (e.g. sudo rm -rf $worktree_dir) and run git worktree prune")
        for msg in "${removal_notes[@]}"; do
          z.io.error "$msg"
        done
        return 1
      fi

      if z.dir.exist $worktree_dir; then
        if sudo rm -rf "$worktree_dir"; then
          removal_completed=true
        else
          removal_notes+=("sudo removal failed: $worktree_dir")
          removal_notes+=("Please remove it manually (e.g. sudo rm -rf $worktree_dir) and run git worktree prune")

          for msg in "${removal_notes[@]}"; do
            z.io.error "$msg"
          done
          return 1
        fi
      else
        removal_completed=true
      fi
    fi
  fi

  if ! z.is_true $removal_completed; then
    return 1
  fi

  if git show-ref --verify --quiet "refs/heads/$actual_branch"; then
    command git branch -D $actual_branch
  fi

  command git worktree prune
}

z.git.worktree.rm._is_registered() {
  local target=$1

  if z.str.empty $target; then
    return 1
  fi

  while IFS= read -r line; do
    if z.str.start_with $line "worktree "; then
      local current=${line#worktree }
      if z.eq $current $target; then
        return 0
      fi
    fi
  done < <(git worktree list --porcelain)

  return 1
}

z.git.worktree.rm._remove_unregistered() {
  local root=$(git worktree list --porcelain | grep '^worktree ' | head -1 | cut -d' ' -f2)
  local tree_root="$root/../${$(basename "$root")}_worktree"

  if z.dir.not_exist $tree_root; then
    z.io.error "Worktree directory does not exist: $tree_root"
    return 1
  fi

  local -a registered_worktrees
  local worktree=""

  while IFS= read -r line; do
    if z.str.start_with $line "worktree "; then
      worktree=${line#worktree }
      registered_worktrees+=("$worktree")
    fi
  done < <(git worktree list --porcelain)

  local removed_count=0
  for dir in $tree_root/*(/N); do
    local normalized_dir=$(cd "$dir" && pwd)
    local is_registered=false

    for registered in "${registered_worktrees[@]}"; do
      if z.eq $normalized_dir $registered; then
        is_registered=true && break
      fi
    done

    if z.eq $is_registered false; then
      local dir_name=$(basename "$dir")
      chmod -R u+w "$dir" 2>/dev/null || true

      if ! z.dir.remove path=$dir 2>/dev/null; then
        z.io.error "  Regular removal failed, trying with sudo..."
        if command -v sudo >/dev/null 2>&1; then
          sudo rm -rf $dir
          if z.status.is_true; then
            removed_count=$((removed_count + 1))
          else
            z.io.error "  Failed to remove: $dir"
            continue
          fi
        else
          z.io.error "  sudo not available, skipping: $dir"
          continue
        fi
      else
        removed_count=$((removed_count + 1))
      fi
    fi
  done

  if z.int.eq $removed_count 0; then
    z.io "No unregistered worktree directories were removed."
  else
    z.io "Successfully removed $removed_count unregistered worktree directories."
  fi
}

_z.git.worktree() {
  local -a subcommands
  subcommands=(
    "to:Create and move to worktree for the specified branch"
    "pr:Create branch from PR number and add to worktree"
    "dev:Create worktree for develop branch and update to latest"
    "list:Display list of worktrees"
    "pt:Save current branch to environment variable"
    "bk:Return to saved branch"
    "cb:Delete worktrees for merged, unprotected branches"
    "rm:Delete worktree for the specified branch"
  )

  local subcommand=""
  local i
  for ((i=2; i<=${#words[@]}; i++)); do
    if z.not_eq ${words[i]} -* ]]; then
      subcommand=${words[i]}
      break
    fi
  done

  if z.is_null $subcommand; then
    _describe "git worktree commands" subcommands
    return
  fi

  case $subcommand in
    "to"|"rm")
      _arguments \
        '-o[Open in VS Code]' \
        '*:branch:->branches'

      if z.eq $state "branches"; then
        local -a branches
        branches=(${(f)"$(git branch --format='%(refname:short)')"})
        _describe "branches" branches
      fi
      ;;
    "pr")
      _message "PR number"
      ;;
  esac
}
