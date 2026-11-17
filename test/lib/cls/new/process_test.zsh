source ${z_main}

z.t.describe "z.cls.new._validate"; {
  z.t.context "書き込み可能な呼出元の変数の場合"; {
    z.t.it "検証だけでは参照を代入しない"; {
      () {
        z.cls.draw NewValidate; {
          z.cls.drew
        }

        local object=""

        z.cls.new._validate NewValidate object

        z.t.expect.status.is.true
        z.t.expect.is.null "$object"
      }
    }
  }

  z.t.context "引数が不足する場合"; {
    z.t.it "作成を拒否する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      z.cls.new._validate # zls: ignore

      z.t.expect.status.is.false
    }
  }

  z.t.context "readonly参照がある場合"; {
    z.t.it "元の実体を保持する"; {
      () {
        z.cls.draw NewValidateReadonly; {
          z.cls.drew
        }

        local object=""
        z.cls.new NewValidateReadonly object
        local original=$object
        z.t.mock name=z.io.error

        z.cls.new._validate NewValidateReadonly object

        z.t.expect.status.is.false
        z.t.expect "$object" "$original"

        z.cls.delete object
      }
    }
  }
}
