source ${z_main}

z.t.describe "z.cls.instance.execute.set"; {
  z.t.context "呼出元のスカラーの場合"; {
    z.t.it "型を保って値を更新する"; {
      () {
        local -i number=1

        z.cls.instance.execute.set number 4

        z.t.expect "$number" 4
        z.t.expect.includes "${(t)number}" integer
      }
    }
  }

  z.t.context "空要素を含む配列の場合"; {
    z.t.it "要素の境界を保って更新する"; {
      () {
        local -a items=(old)

        z.cls.instance.execute.set items "" "two words"

        z.t.expect "${#items}" 2
        z.t.expect "$items[1]" ""
        z.t.expect "$items[2]" "two words"
      }
    }
  }

  z.t.context "スカラーに複数の値を渡す場合"; {
    z.t.it "更新を拒否して元の値を保つ"; {
      () {
        local literal=original

        z.cls.instance.execute.set literal one two

        z.t.expect.status.is.false
        z.t.expect "$literal" original
      }
    }
  }
}
