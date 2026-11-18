source ${z_main}

z.t.describe "z.cls.new._validate"; {
  z.t.context "書き込み可能な呼出元の変数の場合"; {
    z.t.it "検証だけでは参照を代入しない"; {
      () {
        z.cls.draw NewValidate
        z.cls.drew

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
        z.cls.draw NewValidateReadonly
        z.cls.drew

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

  z.t.context "参照を変換する変数属性がある場合"; {
    z.t.it "大文字へ変換する変数には実体を作らない"; {
      () {
        z.cls.draw RejectUpper
        z.cls.drew
        local -u object=""
        z.t.mock name=z.io.error

        z.cls.new RejectUpper object

        z.t.expect.status.is.false
        z.t.expect.is.null "$object"

        z.hash.count z_cls_instances

        z.t.expect.reply 0
      }
    }

    z.t.it "桁揃えする変数には実体を作らない"; {
      () {
        z.cls.draw RejectJustified
        z.cls.drew
        local -L 40 object=""
        z.t.mock name=z.io.error

        z.cls.new RejectJustified object

        z.t.expect.status.is.false

        z.hash.count z_cls_instances

        z.t.expect.reply 0
      }
    }
  }

  z.t.context "値を変換しないタグ付きスカラーの場合"; {
    z.t.it "通常の参照として生成と削除ができる"; {
      () {
        z.cls.draw TaggedBinding
          z.cls.attr count default=3
        z.cls.drew
        local -t object=""

        z.cls.new TaggedBinding object

        z.t.expect.status.is.true

        object.count.get

        z.t.expect.reply 3

        z.cls.delete object

        z.t.expect.status.is.true
      }
    }
  }

}
