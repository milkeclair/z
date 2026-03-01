source ${z_main}

z.t.describe "z.git.branch.merged.get.excludes"; {
  z.t.context "exclude_branchesが渡された場合"; {
    z.t.it "渡されたブランチを返す"; {
      z.git.branch.merged.get.excludes exclude_branches="main master develop"

      z.t.expect.reply "main master develop"
    }
  }

  z.t.context "exclude_branchesが渡されない場合"; {
    z.t.it "デフォルトのブランチを返す"; {
      z.git.branch.merged.get.excludes

      z.t.expect.reply "main master develop release"
    }
  }
}

z.t.describe "z.git.branch.merged.get.remove_symbols"; {
  z.t.context "ブランチ名に対象の記号が含まれる場合"; {
    z.t.it "記号を除去して返す"; {
      z.git.branch.merged.get.remove_symbols "* feature/branch"

      z.t.expect.reply "feature/branch"

      z.git.branch.merged.get.remove_symbols "+ feature/linked"

      z.t.expect.reply "feature/linked"

      z.git.branch.merged.get.remove_symbols "  feature/trimmed"

      z.t.expect.reply "feature/trimmed"
    }
  }
}
