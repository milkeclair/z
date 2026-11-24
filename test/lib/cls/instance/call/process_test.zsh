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
    z.t.it "存在しないインスタンスの操作を拒否する"; {
      z.cls.store._ensure
      z.t.mock name=z.io.error

      z.cls.instance.call._validate "" method run missing

      z.t.expect.status.is.false
    }
  }

  z.t.context "別のインスタンスの呼出しから再入する場合"; {
    z.t.it "実行中のインスタンスを保護する"; {
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
        $object.count.get

        z.t.expect.reply 7

        z.cls.instance.call._access "$object" set count -3
        $object.count.get

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
    z.t.it "復元したインスタンスのスコープで評価する"; {
      () {
        z.cls.draw DirectAccessScope
          z.cls.attr count default=1
          z.cls.attr other default=13
        z.cls.drew

        local object=""
        z.cls.new DirectAccessScope object
        z_cls_values[${object}:count]='typeset -i count=1'

        z.cls.instance.call._access "$object" set count 'other+1'
        $object.count.get

        z.t.expect.reply 14

        z.cls.delete object
      }
    }
  }

  z.t.context "数値setterの式が途中で失敗する場合"; {
    z.t.it "他の属性と保存済みの宣言を変更せず失敗する"; {
      () {
        z.cls.draw FailedSetter
          z.cls.attr count default=4
          z.cls.attr other default=13
          z.cls.method prepare
            $self.count.set 4
          z.cls.method.defined
        z.cls.drew
        local object=""
        z.cls.new FailedSetter object
        () {
          local -i count=4
          z.cls.instance._snapshot "$object" count
        }
        $object.prepare
        local original_count=$z_cls_values[${object}:count]
        local original_other=$z_cls_values[${object}:other]

        z.cls.instance.call._access "$object" set count '(other=9) +' 2>/dev/null

        z.t.expect.status.is.false
        z.t.expect "$z_cls_values[${object}:count]" "$original_count"
        z.t.expect "$z_cls_values[${object}:other]" "$original_other"

        $object.count.get

        z.t.expect.reply 4

        $object.other.get

        z.t.expect.reply 13

        z.cls.delete object
      }
    }
  }
}

z.t.describe "z.cls.instance.call._access_typed"; {
  z.t.context "復元済みのスカラーを取得する場合"; {
    z.t.it "保存値を変換せず取得し、呼出元の同名localを保持する"; {
      () {
        z.cls.store._ensure
        local literal=caller
        z_cls_values[typed_get_ref:literal]="typeset -- literal='false'"

        z.cls.instance.call._access_typed typed_get_ref get literal

        z.t.expect.reply false
        z.t.expect "$literal" caller

        unset 'z_cls_values[typed_get_ref:literal]'
      }
    }
  }

  z.t.context "復元済みのスカラーを更新する場合"; {
    z.t.it "呼出元のlocalを変えず、更新を保存して取得できる"; {
      () {
        z.cls.store._ensure
        local literal=caller
        z_cls_instances[typed_set_ref]=TypedSet
        z_cls_class_attrs[TypedSet]='literal '
        z_cls_values[typed_set_ref:literal]="typeset -- literal='old'"

        z.cls.instance.call._access_typed typed_set_ref set literal null

        z.t.expect.status.is.true

        z.cls.instance.call._access_typed typed_set_ref get literal

        z.t.expect.reply null
        z.t.expect "$literal" caller

        unset 'z_cls_instances[typed_set_ref]' 'z_cls_class_attrs[TypedSet]' 'z_cls_values[typed_set_ref:literal]'
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
          z.cls.method fail
            $self.count.set 4 || return 1
            $self.count.get || return 1
            REPLY="failed:$REPLY"
            return 7
          z.cls.method.defined
        z.cls.drew

        local object=""
        z.cls.new DirectRunScope object

        z.cls.instance.call._run "$object" fail
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
}

# 定義読込時のトラップ設定を初期化のスコープに閉じ込める。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/fixtures/counter.zsh"
  source "$z_root/test/lib/cls/fixtures/arrays.zsh"
  source "$z_root/test/lib/cls/fixtures/typed-state.zsh"
  source "$z_root/test/lib/cls/fixtures/arithmetic-setter.zsh"

  z.t.describe "z.cls.instance._call"; {
    z.t.context "インスタンスを呼び出す場合"; {
      z.t.it "属性を独立して保存し、get/setとメソッドで共有する"; {
        () {
          local first=""
          local second=""
          z.cls.new TestCounter first
          z.cls.new TestCounter second
          $first.increment
          $first.add count=4

          z.t.expect.reply 5

          $second.count.get

          z.t.expect.reply 0

          $first.count.set 10
          $first.increment
          $first.value

          z.t.expect.reply 11

          local literal=$'space "quote" \\ slash\n$(print SHOULD_NOT_RUN)'
          $first.label.set "$literal"
          $first.label.get

          z.t.expect.reply "$literal"

          $first.label.set ""
          $first.label.get

          z.t.expect.reply.is.null

          z.cls.delete first
          z.cls.delete second
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

    z.t.context "メソッドが明示的にreturnする場合"; {
      z.t.it "状態とREPLYと終了コードを保持する"; {
        () {
          local first=""
          z.cls.new TestCounter first
          $first.fail reason
          local call_status=$?
          local call_reply=$REPLY

          z.t.expect "$call_status" 7
          z.t.expect "$call_reply" failure:reason

          $first.value

          z.t.expect.reply 1

          z.cls.delete first
        }
      }
    }

    z.t.context "配列を属性へ保存する場合"; {
      z.t.it "代入後に空の要素と空白を含む要素の境界を保持する"; {
        () {
          local first=""
          z.cls.new ArrayBox first
          () {
            local -a items=()
            z.cls.instance._snapshot "$first" items
          }
          $first.fill
          $first.items.get
          local -a initial_items=("${REPLY[@]}")

          z.t.expect "${#initial_items}" 3
          z.t.expect.is.null "$initial_items[1]"
          z.t.expect "$initial_items[2]" "two words"
          z.t.expect "$initial_items[3]" last

          $first.items.set "" replaced
          $first.items.get
          local -a updated_items=("${REPLY[@]}")

          z.t.expect "${#updated_items}" 2
          z.t.expect.is.null "$updated_items[1]"
          z.t.expect "$updated_items[2]" replaced

          $first.items.set
          $first.items.get
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
          () {
            local -A table=()
            local -i 16 number=0
            local -F 8 fraction=0
            local -aU values=()
            local missing=""
            unset missing
            z.cls.instance._snapshot "$typed" table
            z.cls.instance._snapshot "$typed" number
            z.cls.instance._snapshot "$typed" fraction
            z.cls.instance._snapshot "$typed" values
            z.cls.instance._snapshot "$typed" missing
          }
          $typed.fill
          $typed.verify

          z.t.expect.status.is.true

          () {
            eval "$z_cls_values[${typed}:table]"
            eval "$z_cls_values[${typed}:number]"
            eval "$z_cls_values[${typed}:fraction]"
            eval "$z_cls_values[${typed}:values]"
            eval "$z_cls_values[${typed}:missing]"

            z.t.expect.includes "${(t)table}" association
            if z.str.includes "${(t)table}" association; then
              z.t.expect "$table[space key]" "value words"
              z.t.expect.is.null "$table[empty]"
              z.t.expect "${#table}" 2

              z.var.exists 'table[empty]'

              z.t.expect.status.is.true
            fi

            (( number == 255 ))

            z.t.expect.status.is.true
            z.t.expect.includes "$number" "16#"
            z.t.expect.includes "${(t)number}" integer

            (( fraction == 1.23456789 ))

            z.t.expect.status.is.true
            z.t.expect.includes "${(t)fraction}" float
            z.t.expect "${#values}" 2
            z.t.expect "$values[1]" one
            z.t.expect "$values[2]" two
            z.t.expect.includes "${(t)values}" unique

            z.var.exists missing

            z.t.expect.status.is.false
          }

          local saved_table=$z_cls_values[${typed}:table]
          local saved_number=$z_cls_values[${typed}:number]
          local saved_fraction=$z_cls_values[${typed}:fraction]
          local saved_values=$z_cls_values[${typed}:values]
          local saved_missing=$z_cls_values[${typed}:missing]

          $typed.table.set odd

          z.t.expect.status.is.false
          z.t.expect "$z_cls_values[${typed}:table]" "$saved_table"

          $typed.plain.get

          z.t.expect.reply $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)'

          $typed.verify

          z.t.expect.status.is.true
          z.t.expect "$z_cls_values[${typed}:table]" "$saved_table"
          z.t.expect "$z_cls_values[${typed}:number]" "$saved_number"
          z.t.expect "$z_cls_values[${typed}:fraction]" "$saved_fraction"
          z.t.expect "$z_cls_values[${typed}:values]" "$saved_values"
          z.t.expect "$z_cls_values[${typed}:missing]" "$saved_missing"
          z.t.expect "$number" 77
          z.t.expect "$fraction" 7.5000000000
          z.t.expect "$values[1]" outside

          z.cls.delete typed
        }
      }
    }

    z.t.context "整数setterの式が他の属性を参照する場合"; {
      z.t.it "同じインスタンスのスコープで式を評価する"; {
        () {
          local arithmetic=""
          z.cls.new ArithmeticSetter arithmetic
          () {
            local -i count=0
            z.cls.instance._snapshot "$arithmetic" count
          }
          $arithmetic.prepare
          $arithmetic.count.set 'other+1'
          $arithmetic.count.get

          z.t.expect.reply 14

          z.cls.delete arithmetic
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

    z.t.context "同じインスタンスのメソッドを入れ子で呼ぶ場合"; {
      z.t.it "入れ子の呼び出しで同じselfと実行中フラグを保持する"; {
        () {
          z.cls.draw SameSelf
            z.cls.method identity
              REPLY=$self
            z.cls.method.defined
            z.cls.method nested
              local before=$self
              $self.identity || return 1
              local nested_id=$REPLY
              z.cls.delete "$self" 2>/dev/null
              local delete_status=$?
              REPLY=("$before" "$nested_id" "$self" "$delete_status")
            z.cls.method.defined
          z.cls.drew
          local object=""
          z.cls.new SameSelf object

          $object.nested
          local result=("${REPLY[@]}")

          z.t.expect "${#result}" 4
          z.t.expect "$result[1]" "$object"
          z.t.expect "$result[2]" "$object"
          z.t.expect "$result[3]" "$object"
          z.t.expect "$result[4]" 1

          z.cls.delete object
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
}
