source ${z_main}

z.t.describe "z.arr.includes"; {
  z.t.context "要素が配列に含まれる場合"; {
    z.t.it "trueを返す"; {
      z.arr.includes target=b "a" "b" "c"

      z.t.expect.status.is.true
    }
  }

  z.t.context "要素が配列に含まれない場合"; {
    z.t.it "falseを返す"; {
      z.arr.includes target=d "a" "b" "c"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.arr.excludes"; {
  z.t.context "要素が配列に含まれない場合"; {
    z.t.it "trueを返す"; {
      z.arr.excludes target=d "a" "b" "c"

      z.t.expect.status.is.true
    }
  }

  z.t.context "要素が配列に含まれる場合"; {
    z.t.it "falseを返す"; {
      z.arr.excludes target=b "a" "b" "c"

      z.t.expect.status.is.false
    }
  }
}
