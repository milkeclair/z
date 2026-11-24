source ${z_main}

z.t.describe "z.cls.instance.call._set"; {
  z.t.context "値に空白やシェルの記号がある場合"; {
    z.t.it "受け取った文字列をそのまま保存する"; {
      () {
        z.cls.draw LiteralValue
          z.cls.attr label default=initial
        z.cls.drew
        local object=""
        z.cls.new LiteralValue object
        local literal=$'space "quote" \\ slash\n$(print SHOULD_NOT_RUN)'

        $object.label.set "$literal"
        $object.label.get

        z.t.expect.reply "$literal"

        z.cls.delete object
      }
    }
  }

  z.t.context "引数が二つある場合"; {
    z.t.it "更新を拒否して元の値を保つ"; {
      () {
        z.cls.draw SetWithTwoValues
          z.cls.attr label default=initial
        z.cls.drew
        local object=""
        z.cls.new SetWithTwoValues object

        $object.label.set one "two words"

        z.t.expect.status.is.false

        $object.label.get

        z.t.expect.reply initial

        z.cls.delete object
      }
    }
  }
}

# fixtureの定義でトラップの設定がテストへ漏れないようにする。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/fixtures/counter.zsh"
}

z.t.describe "z.cls.instance.call._run"; {
  z.t.context "メソッドが0以外で戻る場合"; {
    z.t.it "更新とREPLYを保ちactive状態を解放する"; {
      () {
        z.cls.draw DirectRunScope
          z.cls.attr count default=0
          z.cls.method fail
            $self.count.set 4 || return 1
            $self.count.get || return 1
            REPLY="failed:$REPLY"
            return 7
          z.cls.method.defined
        z.cls.drew

        local object=""
        z.cls.new DirectRunScope object

        $object.fail
        local call_status=$?
        local call_reply=$REPLY

        z.t.expect "$call_status" 7
        z.t.expect "$call_reply" failed:4

        z.var.exists "z_cls_active[$object]"

        z.t.expect.status.is.false

        $object.count.get

        z.t.expect.reply 4

        z.cls.delete object
      }
    }
  }

  z.t.context "メソッドが呼び出し前のREPLYを使う場合"; {
    z.t.it "空要素を含む配列を保つ"; {
      () {
        z.cls.draw ReplyScope
          z.cls.method keep
            :
          z.cls.method.defined
        z.cls.drew
        local object=""
        z.cls.new ReplyScope object
        REPLY=(before "two words" "")

        $object.keep

        z.t.expect.reply.is.arr before "two words" ""

        z.cls.delete object
      }
    }
  }

  z.t.context "メソッドでEXITトラップを設定する場合"; {
    z.t.it "トラップからメソッドの引数を参照できる"; {
      () {
        z.cls.draw MethodExitTrap
          z.cls.method finish
            trap 'exit_arg=$1' EXIT
            return 7
          z.cls.method.defined
        z.cls.drew
        local object=""
        local exit_arg=""
        z.cls.new MethodExitTrap object

        $object.finish argument

        z.t.expect "$?" 7
        z.t.expect "$exit_arg" argument

        z.cls.delete object
      }
    }
  }

  z.t.context "同じインスタンスのメソッドを入れ子で呼ぶ場合"; {
    z.t.it "内側と外側で同じ状態を使う"; {
      () {
        local first=""
        z.cls.new TestCounter first
        $first.twice
        $first.value

        z.t.expect.reply 2

        z.cls.delete first
      }
    }
  }

  z.t.context "errexitが有効なメソッド呼び出しの場合"; {
    z.t.it "失敗の後続を実行せず通常のZshと同じ終了コードを返す"; {
      local output=""

      output=$(zsh -f "$z_root/test/lib/cls/fixtures/method-errexit.zsh")

      z.t.expect.status.is.false
      z.t.expect.is.null "$output"
    }
  }

  z.t.context "属性と同名の引数がある場合"; {
    z.t.it "named引数と呼出元のcountを属性から独立して扱う"; {
      () {
        local count=3
        local counter=""
        z.cls.new TestCounter counter
        $counter.count.set 10

        $counter.add count=3
        local add_status=$?
        local add_result=$REPLY

        z.t.expect "$add_status" 0
        z.t.expect "$add_result" 13
        z.t.expect "$count" 3

        $counter.count.get

        z.t.expect.reply 13

        z.cls.delete counter
      }
    }
  }

  z.t.context "別のインスタンスを呼んでから戻る場合"; {
    z.t.it "内側だけselfを切り替え、戻った後は外側のIDを使う"; {
      () {
        z.cls.draw DifferentSelf
          z.cls.method identity
            REPLY=$self
          z.cls.method.defined
          z.cls.method bounce
            local before=$self
            $1.identity || return 1
            local other_id=$REPLY
            $self.identity || return 1
            REPLY=("$before" "$other_id" "$REPLY" "$self")
          z.cls.method.defined
        z.cls.drew
        local first=""
        local second=""
        z.cls.new DifferentSelf first
        z.cls.new DifferentSelf second

        $first.bounce "$second"
        local result=("${REPLY[@]}")

        z.t.expect "${#result}" 4
        z.t.expect "$result[1]" "$first"
        z.t.expect "$result[2]" "$second"
        z.t.expect "$result[3]" "$first"
        z.t.expect "$result[4]" "$first"

        z.cls.delete first
        z.cls.delete second
      }
    }
  }

  z.t.context "selfを読み取る場合"; {
    z.t.it "インスタンスIDをreadonlyで渡し、呼出元のselfを変更しない"; {
      () {
        local -r self=caller_self
        z.cls.draw ReadonlySelf
          z.cls.method inspect
            local before=$self
            (self=replacement) 2>/dev/null
            local assignment_status=$?
            REPLY=("$before" "$self" "$parameters[self]" "$assignment_status")
          z.cls.method.defined
        z.cls.drew
        local object=""
        z.cls.new ReadonlySelf object

        $object.inspect
        local result=("${REPLY[@]}")

        z.t.expect "${#result}" 4
        z.t.expect "$result[1]" "$object"
        z.t.expect "$result[2]" "$object"
        z.t.expect.includes "$result[3]" readonly
        z.t.expect "$result[4]" 1
        z.t.expect "$self" caller_self

        z.cls.delete object
      }
    }
  }
}
