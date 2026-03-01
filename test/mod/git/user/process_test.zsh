source ${z_main}

z.t.describe "z.git.user.local"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git config --local user.nameとuser.emailを実行する"; {
      z.t.mock name="z.io"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "config --local user.name"; then
          echo "Alice"
        elif z.str.start_with "$*" "config --local user.email"; then
          echo "alice@example.com"
        else
          return 1
        fi
      '

      z.git.user.local

      z.t.mock.result name="z.io"
      z.t.expect.reply.is.arr \
        "--- local user info ---" \
        "user.name: Alice" \
        "user.email: alice@example.com"
    }
  }
}

z.t.describe "z.git.user.global"; {
  z.t.context "呼び出した場合"; {
    z.t.it "git config --global user.nameとuser.emailを実行する"; {
      z.t.mock name="z.io"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "config --global user.name"; then
          echo "Alice"
        elif z.str.start_with "$*" "config --global user.email"; then
          echo "alice@example.com"
        else
          return 1
        fi
      '

      z.git.user.global

      z.t.mock.result name="z.io"
      z.t.expect.reply.is.arr \
        "--- global user info ---" \
        "user.name: Alice" \
        "user.email: alice@example.com"
    }
  }
}
