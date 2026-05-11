source ${z_main}

z.t.describe "z.git.branch.label.current"; {
  z.t.context "現在のbranchが存在する場合"; {
    z.t.it "branch名を返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch --show-current"; then
          z.io "main"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.label.current

      z.t.expect.reply "main"
    }
  }

  z.t.context "detached HEADの場合"; {
    z.t.it "detached prefix付きの短いhashを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch --show-current"; then
          return 0
        elif z.str.start_with "$*" "rev-parse --short HEAD"; then
          z.io "abc123"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.label.current

      z.t.expect.reply "detached-abc123"
    }
  }
}

z.t.describe "z.git.branch.label.for"; {
  z.t.context "指定pathのbranchが存在する場合"; {
    z.t.it "branch名を返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "-C /repo/project branch --show-current"; then
          z.io "feature/a"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.label.for /repo/project

      z.t.expect.reply "feature/a"
    }
  }

  z.t.context "指定pathがdetached HEADの場合"; {
    z.t.it "detached prefix付きの短いhashを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "-C /repo/project branch --show-current"; then
          return 0
        elif z.str.start_with "$*" "-C /repo/project rev-parse --short HEAD"; then
          z.io "def456"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.label.for /repo/project

      z.t.expect.reply "detached-def456"
    }
  }
}
