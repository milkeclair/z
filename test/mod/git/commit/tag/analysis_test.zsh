source ${z_main}

z.t.describe "z.git.commit.tag.list"; {
  z.t.context "呼び出されたとき"; {
    z.t.it "有効なコミットタグの配列を返す"; {
      z.git.commit.tag.list

      z.t.expect.reply.is.arr "feat" "fix" "chore" "docs" "style" "refactor" "test"
    }
  }
}
