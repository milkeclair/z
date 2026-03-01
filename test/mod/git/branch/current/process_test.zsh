source ${z_main}

z.t.describe "z.git.branch.current.get"; {
  z.t.context "現在のブランチが存在する場合"; {
    z.t.it "ブランチ名を返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --is-inside-work-tree"; then
          return 0
        elif z.str.start_with "$*" "branch --show-current"; then
          z.io "main"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.current.get

      z.t.expect.reply "main"
    }
  }

  z.t.context "現在のブランチが存在しない場合"; {
    z.t.it "nullを返す"; {
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "rev-parse --is-inside-work-tree"; then
          return 1
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.current.get

      z.t.expect.reply.is.null
    }
  }
}
