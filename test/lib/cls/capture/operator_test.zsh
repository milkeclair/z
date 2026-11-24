source "$z_main"

z.t.describe "z.cls.capture._within_scope"; {
  z.t.context "定義元のスコープが空の場合"; {
    z.t.it "最上位を定義元にすると内側のスコープを含む"; {
      z.cls.capture._within_scope 'inner|outer' ""

      z.t.expect.status.is.true
    }
  }

  z.t.context "定義元が呼出しスタックの途中にある場合"; {
    z.t.it "定義元から呼んだ関数は定義元のスコープ内にある"; {
      z.cls.capture._within_scope 'inner|outer' outer

      z.t.expect.status.is.true
    }
  }

  z.t.context "GLOB_SUBSTが有効な場合"; {
    z.t.it "定義元のアスタリスクを呼出しスタックの文字として照合する"; {
      (
        setopt globsubst

        z.cls.capture._within_scope 'inner|outer' '*'
      )

      z.t.expect.status.is.false
    }
  }
}
