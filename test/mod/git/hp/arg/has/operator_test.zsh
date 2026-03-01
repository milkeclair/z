source ${z_main}

z.t.describe "z.git.hp.arg.has.origin"; {
  z.t.context "引数にoriginが含まれている場合"; {
    z.t.it "trueを返す"; {
      z.git.hp.arg.has.origin "main" "origin" "develop"

      z.t.expect.status.is.true
    }
  }
  z.t.context "引数にoriginが含まれていない場合"; {
    z.t.it "falseを返す"; {
      z.git.hp.arg.has.origin "main" "develop"

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.git.hp.arg.has.develop"; {
  z.t.context "引数にdevelopが含まれている場合"; {
    z.t.it "trueを返す"; {
      z.git.hp.arg.has.develop "main" "origin" "develop"

      z.t.expect.status.is.true
    }
  }
  z.t.context "引数にdevが含まれている場合"; {
    z.t.it "trueを返す"; {
      z.git.hp.arg.has.develop "main" "origin" "dev"

      z.t.expect.status.is.true
    }
  }
  z.t.context "引数にdevelopもdevも含まれていない場合"; {
    z.t.it "falseを返す"; {
      z.git.hp.arg.has.develop "main" "origin"

      z.t.expect.status.is.false
    }
  }
}
