source ${z_main}

z.t.describe "z.git.wt.current.root"; {
  z.t.context "git worktree内の場合"; {
    z.t.it "worktree rootを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --show-toplevel"; then
          z.io "/repo/project"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.wt.current.root

      z.t.expect.reply "/repo/project"
    }
  }

  z.t.context "git worktree外の場合"; {
    z.t.it "失敗する"; {
      z.t.mock name="git" behavior="return 1"

      z.git.wt.current.root

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.git.wt.current.common_dir"; {
  z.t.context "git worktree内の場合"; {
    z.t.it "common git directoryを返す"; {
      z.t.mock name="git" behavior="z.io /repo/project/.git"

      z.git.wt.current.common_dir

      z.t.expect.reply "/repo/project/.git"
    }
  }

  z.t.context "git worktree外の場合"; {
    z.t.it "失敗する"; {
      z.t.mock name="git" behavior="return 1"

      z.git.wt.current.common_dir

      z.t.expect.status.is.false
    }
  }
}
