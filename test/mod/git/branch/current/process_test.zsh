source ${z_main}

z.t.describe "z.git.branch.current.show"; {
  z.t.context "現在のブランチが存在する場合"; {
    z.t.it "現在のブランチ名を返す"; {
      z.t.mock name="git" behavior="z.io main"

      local result=$(z.git.branch.current.show)

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result
      z.t.expect $result "main"
    }
  }

  z.t.context "現在のブランチが存在しない場合"; {
    z.t.it "空文字を返す"; {
      z.t.mock \
        name="git" \
        behavior="z.io.error fatal: not a git repository (or any of the parent directories): .git"

      local result=$(z.git.branch.current.show)

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result
      z.t.expect.is.null $result
    }
  }
}
