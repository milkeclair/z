source ${z_main}

z.t.describe "z.git.commit.help.committer"; {
  z.t.context "呼び出した場合"; {
    z.t.it "コミッターの名前とメールアドレスを表示する"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "config --local user.name"; then
          z.io "Alice"
        elif z.str.start_with "$*" "config --local user.email"; then
          z.io "alice@example.com"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      local result=$(z.git.commit.help.committer)

      z.t.expect "$result" $'\n--- committer ---\nname: Alice\nemail: alice@example.com'
    }
  }
}
