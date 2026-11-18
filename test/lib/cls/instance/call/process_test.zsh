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
        z.cls.draw SignedAccess
          z.cls.attr count default=0
        z.cls.drew

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
        z.cls.draw DirectAccessScope
          z.cls.attr count default=1
          z.cls.attr other default=13
        z.cls.drew

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
        z.cls.draw DirectRunScope
          z.cls.attr count default=0
          z.cls.fn fail 'count=4; REPLY=failed; return 7'
        z.cls.drew

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

# 定義読込時のトラップ設定を初期化のスコープに閉じ込める。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/fixtures/counter.zsh"
  source "$z_root/test/lib/cls/fixtures/arrays.zsh"
  source "$z_root/test/lib/cls/fixtures/typed-state.zsh"
  source "$z_root/test/lib/cls/fixtures/arithmetic-setter.zsh"

  z.t.context "インスタンスを呼び出す場合"; {
    z.t.it "属性を独立して保存し、get/setとメソッドで共有する"; {
      () {
        local first=""
        local second=""
        z.cls.new TestCounter first
        z.cls.new TestCounter second
        first.increment
        first.add 4

        z.t.expect.reply 5

        second.count.get

        z.t.expect.reply 0

        first.count.set 10
        first.increment
        first.value

        z.t.expect.reply 11

        local literal=$'space "quote" \\ slash\n$(print SHOULD_NOT_RUN)'
        first.label.set "$literal"
        first.label.get

        z.t.expect.reply "$literal"

        first.label.set ""
        first.label.get

        z.t.expect.reply.is.null

        z.cls.delete first
        z.cls.delete second
      }
    }
  }

  z.t.context "同じ実体のメソッドを入れ子で呼ぶ場合"; {
    z.t.it "内側と外側で同じ状態を使う"; {
      () {
        local first=""
        z.cls.new TestCounter first
        first.twice first
        first.value

        z.t.expect.reply 2

        z.cls.delete first
      }
    }
  }

  z.t.context "メソッドが明示的にreturnする場合"; {
    z.t.it "状態とREPLYと終了コードを保持する"; {
      () {
        local first=""
        z.cls.new TestCounter first
        first.fail reason
        local call_status=$?
        local call_reply=$REPLY

        z.t.expect "$call_status" 7
        z.t.expect "$call_reply" failure:reason

        first.value

        z.t.expect.reply 1

        z.cls.delete first
      }
    }
  }

  z.t.context "配列を属性へ保存する場合"; {
    z.t.it "空要素と空白を含む要素を更新後も保持する"; {
      () {
        local first=""
        z.cls.new ArrayBox first
        first.fill
        first.items.get
        local -a initial_items=("${REPLY[@]}")

        z.t.expect "${#initial_items}" 3
        z.t.expect.is.null "$initial_items[1]"
        z.t.expect "$initial_items[2]" "two words"
        z.t.expect "$initial_items[3]" last

        first.items.set "" replaced
        first.items.get
        local -a updated_items=("${REPLY[@]}")

        z.t.expect "${#updated_items}" 2
        z.t.expect.is.null "$updated_items[1]"
        z.t.expect "$updated_items[2]" replaced

        first.items.set
        first.items.get
        local empty_count=${#REPLY}

        z.t.expect "$empty_count" 0

        z.cls.delete first
      }
    }
  }

  z.t.context "属性の型とフラグを変更する場合"; {
    z.t.it "保存と復元で型を保ち、呼出元の同名変数を変更しない"; {
      () {
        local -i number=77
        local -F fraction=7.5
        local -a values=(outside)
        local typed=""
        z.cls.new TypedState typed
        typed.fill
        typed.verify

        z.t.expect.status.is.true

        typed.plain.get

        z.t.expect.reply $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)'

        typed.verify

        z.t.expect.status.is.true
        z.t.expect "$number" 77
        z.t.expect "$fraction" 7.5000000000
        z.t.expect "$values[1]" outside

        z.cls.delete typed
      }
    }
  }

  z.t.context "整数setterの式が他の属性を参照する場合"; {
    z.t.it "同じ実体のスコープで式を評価する"; {
      () {
        local arithmetic=""
        z.cls.new ArithmeticSetter arithmetic
        arithmetic.prepare
        arithmetic.count.set 'other+1'
        arithmetic.count.get

        z.t.expect.reply 14

        z.cls.delete arithmetic
      }
    }
  }
}
