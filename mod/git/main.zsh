z.git() {
  case $1 in
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
    git "$@"
    ;;
  esac
}
