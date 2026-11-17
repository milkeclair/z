source ${z_main}

# 定義読込時のトラップ設定を初期化のスコープに閉じ込める。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/counter.zsh"
  source "$z_root/test/lib/cls/arrays.zsh"
  source "$z_root/test/lib/cls/typed-state.zsh"
  source "$z_root/test/lib/cls/arithmetic-setter.zsh"
}

z.t.describe "z.clsの属性"; {
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
