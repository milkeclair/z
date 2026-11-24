source ${z_main}

z.t.describe "z.cls.instance.execute._set"; {
  z.t.context "呼出元のスカラーの場合"; {
    z.t.it "型を保って値を更新する"; {
      () {
        local -i number=1

        z.cls.instance.execute._set number 4

        z.t.expect "$number" 4
        z.t.expect.includes "${(t)number}" integer
      }
    }
  }

  z.t.context "代入先がnameという名前の場合"; {
    z.t.it "呼出元の変数を更新する"; {
      () {
        local name=old

        z.cls.instance.execute._set name new

        z.t.expect "$name" new
      }
    }
  }

  z.t.context "空要素を含む配列の場合"; {
    z.t.it "要素の境界を保って更新する"; {
      () {
        local -a items=(old)

        z.cls.instance.execute._set items "" "two words"

        z.t.expect "${#items}" 2
        z.t.expect.is.null "$items[1]"
        z.t.expect "$items[2]" "two words"
      }
    }
  }

  z.t.context "スカラーに複数の値を渡す場合"; {
    z.t.it "更新を拒否して元の値を保つ"; {
      () {
        local literal=original

        z.cls.instance.execute._set literal one two

        z.t.expect.status.is.false
        z.t.expect "$literal" original
      }
    }
  }

  z.t.context "数値式が不正な場合"; {
    z.t.it "シェルを終了せず整数の元の値を保持する"; {
      () {
        local -i number=4

        z.cls.instance.execute._set number '2 +' 2>/dev/null

        z.t.expect.status.is.false
        z.t.expect "$number" 4
      }
    }

    z.t.it "評価に失敗した式による他の変数への代入を破棄する"; {
      () {
        local -i number=4
        local other=13

        z.cls.instance.execute._set number '(other=9) +' 2>/dev/null

        z.t.expect.status.is.false
        z.t.expect "$number" 4
        z.t.expect "$other" 13
      }
    }
  }

  z.t.context "readonlyの属性の場合"; {
    z.t.it "更新を拒否して元の値を保持する"; {
      () {
        local -ri number=4

        z.cls.instance.execute._set number 5

        z.t.expect.status.is.false
        z.t.expect "$number" 4
      }
    }
  }

  z.t.context "連想配列に奇数個の値を渡す場合"; {
    z.t.it "シェルを終了せず空値を含む元のキーと値を保持する"; {
      () {
        local -A table=(old kept empty "")

        z.cls.instance.execute._set table one two three

        z.t.expect.status.is.false
        z.t.expect "${#table}" 2
        z.t.expect "$table[old]" kept
        z.t.expect.is.null "$table[empty]"

        z.var.exists 'table[empty]'

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "表示精度より細かい浮動小数の場合"; {
    z.t.it "数値の内部精度と型を保って更新する"; {
      () {
        local -F 8 fraction=1

        z.cls.instance.execute._set fraction '1.23456789123456'

        z.t.expect.status.is.true

        (( fraction == 1.23456789123456 ))

        z.t.expect.status.is.true
        z.t.expect.includes "${(t)fraction}" float
      }
    }
  }

}
