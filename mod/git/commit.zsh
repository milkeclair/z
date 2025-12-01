source ./commit/io.zsh

z.git.commit() {
  shift
  z.guard; {
    z.arr.count $@
    if z.int.is.lt $REPLY 2; then
      z.io.empty
      z.git.commit._show_help
      return 1
    fi
  }

  local tag=$1
  local message=$2
  local ticket=""
  local opts=()
  shift 2

  for arg in $@; do
    if z.str.match $arg "-*"; then
      opts+=($arg)
    elif z.is.null $ticket; then
      ticket=$arg
    fi
  done

  if z.is.null $message; then
    z.git.commit._show_help && return 1
  fi


  if z.is.null $ticket && z.str.is.not.match " ${opts[*]} " "* -nt *"; then
    current_branch=$(z.git.hp.current_branch)
    last_part=${current_branch##*-}
    if z.str.match $last_part "^[0-9]+$"; then
      ticket=$last_part
    fi
  fi

  local commit_message="$tag: "
  z.is.not.null $ticket && commit_message+="#$ticket "
  commit_message+=$message

  z.git.commit._with_committer "$commit_message" ${opts[@]}
}

z.git.commit.tdd() {
  local tdd_cycles=("red" "green" "refactor")
  local cycle=$1
  local tag message ticket commit_message=""
  local tags=("feat" "feature" "fix" "chore" "docs" "style" "refactor" "perf" "test" "build" "ci" "revert")

  z.guard; {
    if z.str.is.not.match " ${tdd_cycles[@]} " " $cycle "; then
      z.git.commit.tdd._show_help
      return 1
    fi

    z.arr.count $@
    if z.int.is.lt $REPLY 3; then
      z.git.commit.tdd._show_help
      return 1
    fi
  }

  tag=$2
  message=$3
  ticket=""
  opts=()
  for arg in ${@:4}; do
    if z.str.match $arg "^-"; then
      opts+=($arg)
    elif z.is.null $ticket; then
      ticket=$arg
    fi
  done

  z.guard; {
    if z.is.null $tag || z.is.null $message; then
      z.git.commit.tdd._show_help
      return 1
    fi

    if z.str.is.not.match " ${tags[*]} " " $tag "; then
      z.git.commit.tdd._show_tag_help ${tags[@]}
      return 1
    fi
  }

  if z.is.null $ticket && z.str.is.not.match " ${opts[*]} " " -nt "; then
    current_branch=$(z.git.hp.current_branch)
    after_last_slash=${current_branch##*/}
    first_part=${after_last_slash%%-*}
    last_part=${current_branch##*-}

    if z.str.match $last_part "^[0-9]+$"; then
      ticket=$last_part
    elif z.str.match $first_part "^[0-9]+$"; then
      ticket=$first_part
    fi
  fi

  commit_message="$tag: "
  z.is.not.null $ticket && commit_message+="#$ticket "
  commit_message+="[$cycle] $message"

  z.git.commit._with_committer "$commit_message" ${opts[@]}
}

z.git.commit._with_committer() {
  local message=$1
  local opts=()
  local extra_opts=()
  shift
  for arg in $@; do
    if z.str.match $arg "^-"; then
      opts+=($arg)
    fi
  done

  for opt in ${opts[@]}; do
    if z.is.eq $opt "-ca"; then
      extra_opts+=("--amend")
    elif z.is.eq $opt "-ae"; then
      extra_opts+=("--allow-empty")
    fi
  done

  command git commit -m "$message" ${extra_opts[@]}
  z.git.commit._show_committer
}
