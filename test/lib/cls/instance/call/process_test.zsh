source ${z_main}

z.t.describe "z.cls.instance.call._validate"; {
  z.t.context "公開済みのメソッドの場合"; {
    z.t.it "実行を許可する"; {
      z.cls.store._ensure
      z_cls_instances[validate_ref]=ValidateCall
      z_cls_bodies[ValidateCall:run]=':'

      z.cls.instance.call._validate validate_ref method run object

      z.t.expect.status.is.true

      unset 'z_cls_instances[validate_ref]' 'z_cls_bodies[ValidateCall:run]'
    }
  }

  z.t.context "参照がない場合"; {
    z.t.it "存在しない実体の操作を拒否する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      z.cls.instance.call._validate "" method run missing

      z.t.expect.status.is.false
    }
  }

  z.t.context "別の実体の呼出しから再入する場合"; {
    z.t.it "実行中の実体を保護する"; {
      z.cls.store._ensure
      z_cls_instances[reentry_ref]=ValidateReentry
      z_cls_bodies[ValidateReentry:run]=':'
      z_cls_active[reentry_ref]=1
      z.t.mock name=z.io.error

      () {
        local z_cls_current_instance=another_ref

        z.cls.instance.call._validate reentry_ref method run object

        z.t.expect.status.is.false
      }

      unset 'z_cls_instances[reentry_ref]' 'z_cls_bodies[ValidateReentry:run]' 'z_cls_active[reentry_ref]'
    }
  }
}

z.t.describe "z.cls.instance.call._access"; {
  z.t.context "符号付きの整数を更新する場合"; {
    z.t.it "正負の符号を共通の整数判定で扱う"; {
      () {
        z.cls.draw SignedAccess; {
          z.cls.attr count 0
          z.cls.drew
        }

        local object=""
        z.cls.new SignedAccess object
        z_cls_values[${object}:count]='typeset -i count=0'

        z.cls.instance.call._access "$object" set count +7
        object.count.get

        z.t.expect.reply 7

        z.cls.instance.call._access "$object" set count -3
        object.count.get

        z.t.expect.reply -3

        z.cls.delete object
      }
    }
  }

  z.t.context "保存済みのスカラーの場合"; {
    z.t.it "リテラルを変換せず取得する"; {
      z.cls.store._ensure
      z_cls_values[access_ref:literal]="typeset -- literal='false'"

      z.cls.instance.call._access access_ref get literal

      z.t.expect.reply false

      unset 'z_cls_values[access_ref:literal]'
    }

    z.t.it "引数のあるgetterを拒否して保存値を保つ"; {
      z.cls.store._ensure
      z_cls_values[access_ref:literal]="typeset -- literal='false'"

      z.cls.instance.call._access access_ref get literal extra

      z.t.expect.status.is.false
      z.t.expect "$z_cls_values[access_ref:literal]" "typeset -- literal='false'"

      unset 'z_cls_values[access_ref:literal]'
    }
  }

  z.t.context "整数setterが他の属性を参照する場合"; {
    z.t.it "復元した実体のスコープで評価する"; {
      () {
        z.cls.draw DirectAccessScope; {
          z.cls.attr count 1
          z.cls.attr other 13
          z.cls.drew
        }

        local object=""
        z.cls.new DirectAccessScope object
        z_cls_values[${object}:count]='typeset -i count=1'

        z.cls.instance.call._access "$object" set count 'other+1'
        object.count.get

        z.t.expect.reply 14

        z.cls.delete object
      }
    }
  }
}

z.t.describe "z.cls.instance.call._run"; {
  z.t.context "メソッドが0以外で戻る場合"; {
    z.t.it "更新とREPLYを保ちactive状態を解放する"; {
      () {
        z.cls.draw DirectRunScope; {
          z.cls.attr count 0
          z.cls.fn fail 'count=4; REPLY=failed; return 7'
          z.cls.drew
        }

        local object=""
        z.cls.new DirectRunScope object

        z.cls.instance.call._run "$object" method fail
        local call_status=$?
        local call_reply=$REPLY

        z.t.expect "$call_status" 7
        z.t.expect "$call_reply" failed

        z.var.exists "z_cls_active[$object]"

        z.t.expect.status.is.false

        object.count.get

        z.t.expect.reply 4

        z.cls.delete object
      }
    }
  }
}
