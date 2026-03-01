source ${z_main}

z.t.describe "z.git.status.is.dirty"; {
  z.t.context "git statusがdirtyな場合"; {
    z.t.it "trueを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "status --porcelain"; then
          z.io " M modified-file.txt"
          return 0
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.status.is.dirty

      z.t.expect.status.is.true
    }
  }

  z.t.context "git statusがcleanな場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "status --porcelain"; then
          z.io ""
          return 0
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.status.is.dirty

      z.t.expect.status.is.false
    }
  }
}
