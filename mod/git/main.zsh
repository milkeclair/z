z.git() {
  case $1 in
  "add")
    z.git.add "$@"
    ;;
  "a")
    z.git.add "$@"
    ;;
  "c")
    z.git.commit "$@"
    ;;
  "tdd")
    z.git.commit.tdd "$@"
    ;;
  "red")
    z.git.commit.tdd "$@"
    ;;
  "1")
    shift
    z.git.commit.tdd red "$@"
    ;;
  "green")
    z.git.commit.tdd "$@"
    ;;
  "2")
    shift
    z.git.commit.tdd green "$@"
    ;;
  "push")
    z.git.push "$@"
    ;;
  "pull")
    z.git.pull "$@"
    ;;
  "current")
    z.git.branch.current.show
    ;;
  "user")
    z.git.user "$@"
    ;;
  "l")
    z.git.log "$@"
    ;;
  "stats")
    z.git.stats "$@"
    ;;
  "fetch")
    command git fetch --prune
    command echo "Fetched all branches and tags from remote."
    ;;
  "to")
    shift
    z.git.wt.to "$@"
    ;;
  "pr")
    z.git.wt.pr "$2"
    ;;
  "dev")
    z.git.wt.dev
    ;;
  "list")
    z.git.wt.list
    ;;
  "pt")
    z.git.wt.pt "$2"
    ;;
  "bk")
    z.git.wt.bk "$2"
    ;;
  "cb")
    z.git.wt.cb
    ;;
  "rm")
    z.git.wt.rm "$@"
    ;;
  *)
    command git "$@"
    ;;
  esac
}

_z.git() {
  local -a subcommands
  subcommands=(
    "commit:create a commit"
    "c:create a commit (short form)"
    "tdd:TDD commit"
    "red:RED (test failure) commit"
    "1:RED (test failure) commit"
    "green:GREEN (test success) commit"
    "2:GREEN (test success) commit"
    "push:push"
    "pull:pull"
    "current:show current branch"
    "user:user settings"
    "l:show logs"
    "stats:show statistics"
    "fetch:fetch remote branches and tags"
    "to:create and move to a worktree for the specified branch"
    "pr:create a branch from a pull request number and add a worktree"
    "dev:create a worktree for the develop branch and update it to the latest state"
    "list:list worktrees"
    "pt:save the current branch to an environment variable"
    "bk:switch back to the saved branch in the environment variable"
    "cb:remove merged branch worktrees"
    "rm:remove the worktree for the specified branch"
  )

  if ((CURRENT == 2)); then
    _describe "z.git subcommand" subcommands
  elif ((CURRENT >= 3)); then
    case "$words[2]" in
      "to"|"pr"|"dev"|"list"|"pt"|"bk"|"cb"|"rm")
        _z.git.wt
        ;;
      *)
        _default
        ;;
    esac
  fi
}
