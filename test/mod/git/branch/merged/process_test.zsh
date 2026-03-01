source ${z_main}

z.t.describe "z.git.branch.merged.get"; {
  z.t.context "マージ済みブランチを取得する場合"; {
    z.t.it "スペース区切りで返す"; {
      local merged="  current-branch\n  feature/a\n  feature/b\n  feature/c"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch --merged"; then
          z.io "$merged"
        elif z.str.start_with "$*" "branch --show-current"; then
          z.io "current-branch"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.merged.get

      z.t.expect.reply "feature/a feature/b feature/c"
    }
  }

  z.t.context "*や+を含むマージ済みブランチを取得する場合"; {
    z.t.it "*や+を除去し、対象ブランチをスペース区切りで返す"; {
      local merged="* main\n+ feature/linked\n  develop\n  release\n  feature/a\n  feature/b"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch --merged"; then
          z.io "$merged"
        elif z.str.start_with "$*" "branch --show-current"; then
          z.io "main"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.merged.get

      z.t.expect.reply "feature/linked feature/a feature/b"
    }
  }

  z.t.context "exclude_branchesが渡された場合"; {
    z.t.it "指定されたブランチを除外する"; {
      local merged="* main\n+ feature/linked\n  develop\n  release\n  feature/a\n  feature/b"
      z.t.mock name="git" behavior='
        if z.str.start_with "$*" "branch --merged"; then
          z.io "$merged"
        elif z.str.start_with "$*" "branch --show-current"; then
          z.io "main"
        else
          z.io "Unexpected git command: $*"
          return 1
        fi
      '

      z.git.branch.merged.get exclude_branches="main master feature/a"

      z.t.expect.reply "feature/linked develop release feature/b"
    }
  }
}
