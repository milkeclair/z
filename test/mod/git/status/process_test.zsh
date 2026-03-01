source ${z_main}

z.t.describe "z.git.status"; {
  z.t.context "upstreamが存在し、ローカルとリモートの差分がある場合"; {
    z.t.it "差分を表示する"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --symbolic-full-name @{u}"; then
          z.io "refs/remotes/origin/main"
        elif z.str.start_with "$*" "rev-list --count refs/remotes/origin/main..HEAD"; then
          z.io "3"
        elif z.str.start_with "$*" "status --short"; then
          z.io " M modified-file.txt"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      local result=$(z.git.status)

      z.t.expect.includes "$result" "'refs/remotes/origin/main' by 3 commits."
      z.t.expect.includes "$result" " M modified-file.txt"
    }
  }

  z.t.context "upstreamが存在しない場合"; {
    z.t.it "差分を表示せず、git statusの結果のみを表示する"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --symbolic-full-name @{u}"; then
          z.io ""
          return 1
        elif z.str.start_with "$*" "rev-list --count ..HEAD"; then
          z.io ""
          return 1
        elif z.str.start_with "$*" "status --short"; then
          z.io " M modified-file.txt"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      local result=$(z.git.status)

      z.t.expect.excludes "$result" "by"
      z.t.expect.includes "$result" " M modified-file.txt"
    }
  }

  z.t.context "upstreamが存在し、ローカルとリモートの差分がない場合"; {
    z.t.it "差分を表示せず、git statusの結果のみを表示する"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --symbolic-full-name @{u}"; then
          z.io "refs/remotes/origin/main"
        elif z.str.start_with "$*" "rev-list --count refs/remotes/origin/main..HEAD"; then
          z.io "0"
        elif z.str.start_with "$*" "status --short"; then
          z.io " M modified-file.txt"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      local result=$(z.git.status)

      z.t.expect.excludes "$result" "by"
      z.t.expect.includes "$result" " M modified-file.txt"
    }
  }
}
