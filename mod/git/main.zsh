source ./helper.zsh
source ./commit.zsh
source ./push.zsh
source ./pull.zsh
source ./protect.zsh
source ./user.zsh
source ./log.zsh
source ./stat.zsh
source ./worktree.zsh

z.git() {
  case $1 in
  "c")
    z.git.commit "$@"
    ;;
  "tdd")
    z.git.commit.tdd
    ;;
  "red")
    z.git.commit.tdd "$@"
    ;;
  "1")
    shift
    z.git.commit.tdd "red" "$@"
    ;;
  "green")
    z.git.commit.tdd "$@"
    ;;
  "2")
    shift
    z.git.commit.tdd "green" "$@"
    ;;
  "push")
    z.git.push "$@"
    ;;
  "pull")
    z.git.pull "$@"
    ;;
  "current")
    z.git.hp.show_current
    ;;
  "user")
    z.git.user "$@"
    ;;
  "logs")
    z.git.log "$@"
    ;;
  "l")
    z.git.log "$@"
    ;;
  "stats")
    z.git.stat
    ;;
  "fetch")
    command git fetch --prune
    command echo "Fetched all branches and tags from remote."
    ;;
  "to")
    shift
    z.git.worktree.to "$@"
    ;;
  "pr")
    z.git.worktree.pr "$2"
    ;;
  "dev")
    z.git.worktree.dev
    ;;
  "list")
    z.git.worktree.list
    ;;
  "pt")
    z.git.worktree.pt "$2"
    ;;
  "bk")
    z.git.worktree.bk "$2"
    ;;
  "cb")
    z.git.worktree.cb
    ;;
  "rm")
    z.git.worktree.rm "$@"
    ;;
  *)
    command git "$@"
    ;;
  esac
}

_
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
    "protect:protect branch"
    "unprotect:remove branch protection"
    "protected:list protected branches"
    "current:show current branch"
    "user:user settings"
    "logs:show logs"
    "l:show logs (short form)"
    "stats:show statistics"
    "fetch:fetch remote branches and tags"
    "to:create and move to a worktree for the specified branch"
    "pr:create a branch from a pull request number and add a worktree"
    "dev:create a worktree for the develop branch and update it to the latest state"
    "list:list worktrees"
    "pt:save the current branch to an environment variable"
    "bk:switch back to the saved branch in the environment variable"
    "cb:remove merged and unprotected branch worktrees"
    "rm:remove the worktree for the specified branch"
  )

  if ((CURRENT == 2)); then
    _describe "z.git subcommand" subcommands
  elif ((CURRENT >= 3)); then
    case "$words[2]" in
      "to"|"pr"|"dev"|"list"|"pt"|"bk"|"cb"|"rm")
        _z.git.worktree
        ;;
      *)
        _default
        ;;
    esac
  fi
}
