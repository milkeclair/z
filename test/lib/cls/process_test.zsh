source ${z_main}

z.t.describe "z.cls.draw"; {
  z.t.context "有効なクラス名の場合"; {
    z.t.it "定義を開始する"; {
      z.cls.draw DirectDraw
        z.t.expect "$z_cls_drawing" DirectDraw

      z.cls.abort
    }
  }

  z.t.context "引数が不足する場合"; {
    z.t.it "失敗する"; {
      z.t.mock name=z.io.error

      z.cls.draw # zls: ignore
      z.cls.drew

      z.t.expect.status.is.false
    }
  }

}

# 定義読込時のトラップ設定を初期化のスコープに閉じ込める。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/fixtures/counter.zsh"
  source "$z_root/test/lib/cls/fixtures/arrays.zsh"
}

z.t.describe "z.cls.attr"; {
  z.t.context "定義中の属性の場合"; {
    z.t.it "初期値を保持する"; {
      z.cls.draw DirectAttr
        z.cls.attr literal default=false

        z.t.expect "$z_cls_defaults[DirectAttr:literal]" false

      z.cls.abort
    }
  }

  z.t.context "同名属性がある場合"; {
    z.t.it "上書きを拒否する"; {
      z.cls.draw DuplicateAttr
        z.cls.attr count default=3
        z.t.mock name=z.io.error

        z.cls.attr count default=9

        z.t.expect.status.is.false
        z.t.expect "$z_cls_defaults[DuplicateAttr:count]" 3

      z.cls.abort
    }
  }
  z.t.context "defaultが空文字または省略の場合"; {
    z.t.it "空の初期値は受け付け、初期値を省略したクラスは公開しない"; {
      z.cls.draw EmptyDefault
        z.cls.attr default default=
        z.cls.attr default=0 count
      z.cls.drew

      () {
        local object=""
        z.cls.new EmptyDefault object
        $object.default.get

        z.t.expect.reply.is.null

        $object.count.get
        local reply_kind=${(t)REPLY}
        local count_value=$REPLY

        z.t.expect "$reply_kind" scalar
        z.t.expect "$count_value" 0
        z.cls.delete object
      }

      z.cls.draw MissingDefault
        z.cls.attr value 2>/dev/null # zls: ignore missing-named-argument

        z.t.expect.status.is.false
      z.cls.drew

      z.t.expect.status.is.false
      z.var.exists 'z_cls_classes[MissingDefault]'

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.fn"; {
  z.t.context "明示的な本体の場合"; {
    z.t.it "クラスへ登録する"; {
      z.cls.draw DirectMethod
        z.cls.fn value 'REPLY=literal'

        z.t.expect "$z_cls_bodies[DirectMethod:value]" 'REPLY=literal'

      z.cls.abort
    }
  }
}

z.t.describe "z.cls.drew"; {
  z.t.context "定義を開始していない場合"; {
    z.t.it "公開を拒否する"; {
      z.cls.abort
      z.t.mock name=z.io.error

      z.cls.drew

      z.t.expect.status.is.false
    }
  }

  z.t.context "定義中のクラスの場合"; {
    z.t.it "公開して定義状態を終了する"; {
      z.cls.draw DirectPublish
      z.cls.drew

      z.t.expect "$z_cls_classes[DirectPublish]" 1
      z.t.expect.is.null "$z_cls_drawing"
    }
  }
}

z.t.describe "z.cls.abort"; {
  z.t.context "呼出元にreadonly argがある場合"; {
    z.t.it "呼出元を変更せずに定義を破棄する"; {
      z.cls.draw ReadonlyAbort
        z.cls.attr count default=0

        () {
          local -r arg=untouched

          z.cls.abort

          z.t.expect.status.is.true
          z.t.expect "$arg" untouched
        }

        z.t.expect.is.null "$z_cls_drawing"
    }
  }

  z.t.context "未公開の定義がある場合"; {
    z.t.it "初期値と本体を破棄する"; {
      z.cls.draw DirectAbort
        z.cls.attr count default=0
        z.cls.fn value '$self.count.get'

      z.cls.abort

      z.t.expect.is.null "$z_cls_drawing"

      z.var.exists 'z_cls_defaults[DirectAbort:count]'

      z.t.expect.status.is.false

      z.var.exists 'z_cls_bodies[DirectAbort:value]'

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.new"; {
  z.t.context "既定値を共有する場合"; {
    z.t.it "未変更の属性を保持せず、明示した空文字だけを実体に保存する"; {
      () {
        z.cls.draw SharedDefaults
          z.cls.attr label default=initial
        z.cls.drew

        local first="" second=""
        z.cls.new SharedDefaults first
        z.cls.new SharedDefaults second

        $first.label.get

        z.t.expect.reply initial
        z.t.expect "${+z_cls_scalars[${first}:label]}" 0
        z.t.expect "${+z_cls_values[${first}:label]}" 0

        $first.label.set ""
        $first.label.get

        z.t.expect.reply.is.null
        z.t.expect "${+z_cls_scalars[${first}:label]}" 1

        $second.label.get

        z.t.expect.reply initial
        z.t.expect "${+z_cls_scalars[${second}:label]}" 0

        z.cls.delete first

        z.t.expect "${+z_cls_scalars[${first}:label]}" 0
        z.cls.delete second
      }
    }
  }

  z.t.context "nounsetの下で参照をコピーした場合"; {
    z.t.it "nounset下でコピーした参照の状態共有と削除ができる"; {
      local -a output=()
      output=("${(@f)$(
        setopt nounset
        local counter=""
        z.cls.new TestCounter counter
        local -r other=$counter
        "$other.increment"
        $counter.count.get
        print -rl -- "$REPLY"
        $counter.add count=4
        "$other.value"
        print -rl -- "$REPLY"
        z.cls.delete other
        print -rl -- "${+functions[$counter.value]}"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 3
      z.t.expect "$output[1]" 1
      z.t.expect "$output[2]" 5
      z.t.expect "$output[3]" 0
    }
  }

  z.t.context "変換すると意味が変わる名前と属性値の場合"; {
    z.t.it "falseというクラス名とnullという文字列を保つ"; {
      () {
        z.cls.draw false
          z.cls.attr literal default=null
        z.cls.drew

        local object=""

        z.cls.new false object
        $object.literal.get

        z.t.expect.reply null

        z.cls.delete object
      }
    }
  }

  z.t.context "呼出元に内部変数と同名のlocalがある場合"; {
    z.t.it "生成・メソッド・削除が呼出元の変数を変更しない"; {
      () {
        local -r z_cls_instance=caller_instance
        local -r z_cls_class=caller_class
        z.cls.draw ScopedInternals
          z.cls.attr count default=0
          z.cls.fn increment access=write '$self.count.get || return 1; $self.count.set "$(( REPLY + 1 ))" || return 1; $self.count.get'
        z.cls.drew

        local object=""
        z.cls.new ScopedInternals object
        $object.increment

        z.t.expect.reply 1
        z.t.expect "$z_cls_instance" caller_instance
        z.t.expect "$z_cls_class" caller_class

        z.cls.delete object

        z.t.expect.status.is.true
        z.t.expect "$z_cls_instance" caller_instance
        z.t.expect "$z_cls_class" caller_class
      }
    }
  }

  z.t.context "二重アンダースコアから始まる属性を使う場合"; {
    z.t.it "内部変数と衝突せず状態を保存する"; {
      () {
        z.cls.draw FormerPrefix
          z.cls.attr __z_cls_value default=0
          z.cls.fn increment access=write '$self.__z_cls_value.get || return 1; $self.__z_cls_value.set "$(( REPLY + 1 ))" || return 1; $self.__z_cls_value.get'
        z.cls.drew

        local object=""
        z.cls.new FormerPrefix object

        $object.increment

        z.t.expect.reply 1

        $object.__z_cls_value.get

        z.t.expect.reply 1

        z.cls.delete object

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "argを参照名として使う場合"; {
    z.t.it "readonly化した参照を返し、取得と削除ができる"; {
      z.cls.draw ArgumentBinding
        z.cls.attr count default=3
      z.cls.drew

      () {
        local arg=""

        z.cls.new ArgumentBinding arg

        z.t.expect.status.is.true

        $arg.count.get

        z.t.expect.reply 3

        z.cls.delete arg

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "呼出元に別のreadonly argがある場合"; {
    z.t.it "既存の変数を変えずに生成と削除ができる"; {
      z.cls.draw ReadonlyArgument
        z.cls.attr count default=7
      z.cls.drew

      () {
        local -r arg=untouched
        local object=""

        z.cls.new ReadonlyArgument object

        z.t.expect.status.is.true

        $object.count.get

        z.t.expect.reply 7

        z.cls.delete object

        z.t.expect.status.is.true
        z.t.expect "$arg" untouched
      }
    }
  }

  z.t.context "クラスが存在しない場合"; {
    z.t.it "実体を作らず失敗する"; {
      z.t.mock name=z.io.error

      z.cls.new MissingDirectClass missing_direct_object

      z.t.expect.status.is.false
    }
  }

  z.t.context "公開したクラスの場合"; {
    z.t.it "readonly参照を呼出元へ返す"; {
      () {
        z.cls.draw DirectNew
          z.cls.attr count default=0
        z.cls.drew

        local object=""
        z.cls.new DirectNew object

        z.t.expect.reply "$object"
        z.t.expect.includes "$parameters[object]" readonly

        $object.count.get

        z.t.expect.reply 0

        z.cls.delete object
      }
    }
  }

  z.t.context "内側のスコープに同名localがある場合"; {
    z.t.it "内側の実体を削除しても外側の参照と状態を保持する"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        local outer_id=$counter
        $counter.count.set 10

        () {
          local counter=""

          z.cls.new TestCounter counter

          z.t.expect.status.is.true
          z.t.expect.not "$counter" "$outer_id"

          $counter.increment
          $counter.count.get

          z.t.expect.reply 1

          z.cls.delete counter

          z.t.expect.status.is.true
        }

        z.t.expect "$counter" "$outer_id"

        $counter.count.get

        z.t.expect.reply 10

        z.cls.delete counter
        z.var.exists "functions[$counter.increment]"

        z.t.expect.status.is.false
      }
    }

    z.t.it "内側の参照が別クラスを指す場合も呼び分ける"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        $counter.count.set 8

        () {
          local counter=""

          z.cls.new ArrayBox counter

          z.t.expect.status.is.true

          () {
            local -a items=()
            z.cls.instance._snapshot "$counter" items
          }
          $counter.fill
          $counter.items.get
          local item_count=${#REPLY}

          z.t.expect "$item_count" 3

          z.var.exists "functions[$counter.count.get]"

          z.t.expect.status.is.false

          z.cls.delete counter
        }

        $counter.count.get

        z.t.expect.reply 8

        z.cls.delete counter
      }
    }
  }

  z.t.context "readonlyの参照を保持する場合"; {
    z.t.it "参照の再代入と再生成を拒否し、属性は更新できる"; {
      () {
        local counter=""
        z.cls.new TestCounter counter

        z.t.expect.includes "$parameters[counter]" local
        z.t.expect.includes "$parameters[counter]" readonly

        (counter=other) 2>/dev/null

        z.t.expect.status.is.false

        z.cls.new TestCounter counter 2>/dev/null

        z.t.expect.status.is.false

        local copy=$counter

        z.cls.new TestCounter copy 2>/dev/null

        z.t.expect.status.is.false

        $counter.count.set 3
        $counter.increment

        z.t.expect.reply 4

        z.cls.delete counter
      }
    }
  }

  z.t.context "参照変数と同じ接頭辞を持つ関数がある場合"; {
    z.t.it "既存の関数を保ち、実体ID付きの関数だけを登録する"; {
      first.value() {
        REPLY=original
      }

      local first=""
      z.cls.new TestCounter first && $first.value
      local result_code=$? result_value=$REPLY

      z.t.expect "$result_code" 0
      z.t.expect "$result_value" 0
      first.value
      z.t.expect.reply original

      z.var.exists 'functions[first.increment]'
      z.t.expect.status.is.false

      z.cls.delete first
      unfunction first.value
    }
  }
}

z.t.describe "z.cls.borrow"; {
  z.t.context "読み取り専用で貸し出す場合"; {
    z.t.it "借用中だけgetterを使え、所有者側の変更も拒否する"; {
      () {
        z.cls.draw ReadOnlyBorrow
          z.cls.attr count default=5
          z.cls.fn value '$self.count.get'
          z.cls.fn write_value access=write '$self.count.set 6'
          z.cls.fn leak_self 'REPLY=$self'
          z.cls.fn keep_reply ':'
          z.cls.fn try_write 'z.cls.instance.call._set "$self" count 6'
        z.cls.drew

        local owner="" destination="" escaped=""
        z.cls.new ReadOnlyBorrow owner || return 1
        read_borrowed_count() {
          local borrowed=$1
          escaped=$borrowed
          local setter=$borrowed.count.set
          z.t.expect "${+functions[$setter]}" 0

          $owner.count.set 7 2>/dev/null
          z.t.expect.status.is.false
          $owner.write_value 2>/dev/null
          z.t.expect.status.is.false

          $borrowed.value
          z.t.expect.reply 5
          z.cls.owner.move from=owner to=destination 2>/dev/null
          z.t.expect.status.is.false
          z.cls.delete owner 2>/dev/null
          z.t.expect.status.is.false

          $borrowed.count.get || return 1
          return 7
        }

        local result=0
        z.cls.borrow from=owner read_borrowed_count || result=$?
        local reply=$REPLY
        z.t.expect "$result" 7
        z.t.expect "$reply" 5

        local getter=$escaped.count.get
        z.t.expect "${+functions[$getter]}" 0
        z.t.expect "${+z_cls_references[$escaped]}" 0

        REPLY=(before call)
        $owner.keep_reply
        z.t.expect.reply.is.arr before call

        $owner.leak_self
        local leaked=$REPLY
        z.t.expect "${+z_cls_references[$leaked]}" 0

        $owner.try_write 2>/dev/null
        z.t.expect.status.is.false

        $owner.count.set 8
        $owner.value
        z.t.expect.reply 8
        z.cls.delete owner
        unfunction read_borrowed_count
      }
    }
  }

  z.t.context "借用中に同じ実体をもう一度貸し出す場合"; {
    z.t.it "内側の借用だけを終了し、外側が戻るまで所有者の更新を拒否する"; {
      () {
        local owner="" escaped=""
        z.cls.new TestCounter owner || return 1

        read_inner_borrow() {
          local borrowed=$1
          escaped=$borrowed
          $borrowed.count.get
        }

        read_outer_borrow() {
          local borrowed=$1
          z.cls.borrow from=owner read_inner_borrow || return 1
          local inner_getter=$escaped.count.get
          z.t.expect "${+functions[$inner_getter]}" 0

          $owner.count.set 9 2>/dev/null
          z.t.expect.status.is.false

          $borrowed.count.get
        }

        z.cls.borrow from=owner read_outer_borrow
        z.t.expect.reply 0

        $owner.count.set 9
        $owner.count.get
        z.t.expect.reply 9
        z.cls.delete owner
        unfunction read_outer_borrow read_inner_borrow
      }
    }
  }

  z.t.context "一時参照のコマンド名が途中で衝突する場合"; {
    z.t.it "既存関数を残し、今回登録した関数と借用状態を片付ける"; {
      () {
        z.cls.draw BorrowCollision
          z.cls.attr count default=0
          z.cls.fn value '$self.count.get'
        z.cls.drew

        local owner="" called=0
        z.cls.new BorrowCollision owner || return 1
        unused_borrow_callback() { called=1 }

        local candidate="z_cls_ref_${$}_$(( z_cls_next_reference + 1 ))"
        local occupied=$candidate.count.get
        local prepared=$candidate.value
        functions[$occupied]='REPLY=existing'
        local before=$functions[$occupied]

        z.cls.borrow from=owner unused_borrow_callback 2>/dev/null
        z.t.expect.status.is.false

        z.t.expect "$called" 0
        z.t.expect "$functions[$occupied]" "$before"
        z.t.expect "${+functions[$prepared]}" 0
        z.t.expect "${+z_cls_references[$candidate]}" 0
        z.t.expect "${+z_cls_borrow_counts[$owner]}" 0

        unfunction "$occupied" unused_borrow_callback
        z.cls.delete owner
      }
    }
  }

  z.t.context "コールバックが一時コマンドを置き換えた場合"; {
    z.t.it "置き換えた関数を残し、元の実体への参照を失効させる"; {
      () {
        local owner="" borrowed=""
        z.cls.new TestCounter owner || return 1
        replace_borrow_callback() {
          borrowed=$1
          local replacement=$borrowed.value
          functions[$replacement]='REPLY=replaced'
        }

        z.cls.borrow from=owner replace_borrow_callback
        z.t.expect.status.is.true

        local replacement=$borrowed.value
        local getter=$borrowed.count.get

        "$replacement"
        z.t.expect.reply replaced
        z.t.expect "${+functions[$getter]}" 0
        z.t.expect "${+z_cls_references[$borrowed]}" 0

        unfunction "$replacement" replace_borrow_callback
        z.cls.delete owner
      }
    }
  }

  z.t.context "コールバックを特定できない場合"; {
    z.t.it "所有者の更新権限を保ったまま失敗する"; {
      () {
        local owner=""
        z.cls.new TestCounter owner || return 1
        z.cls.borrow from=owner missing_borrow_callback 2>/dev/null
        z.t.expect.status.is.false

        $owner.count.set 6
        $owner.count.get
        z.t.expect.reply 6
        z.cls.delete owner
      }
    }
  }
}

z.t.describe "z.cls.delete"; {
  z.t.context "errexitが有効な場合"; {
    z.t.it "errexit下で生成した関数と状態を削除する"; {
      local -a output=()
      output=("${(@f)$(
        setopt errexit
        local counter=""
        z.cls.new TestCounter counter
        $counter.increment
        z.cls.delete counter
        print -rl -- "${#z_cls_instances}" "${+functions[$counter.increment]}"
      )}")

      z.t.expect.status.is.true
      z.t.expect "${#output}" 2
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 0
    }
  }

  z.t.context "実行中の実体の場合"; {
    z.t.it "状態を保持して削除を拒否する"; {
      () {
        z.cls.draw ActiveDelete
          z.cls.attr count default=3
        z.cls.drew

        local object=""
        z.cls.new ActiveDelete object
        z_cls_active[$object]=1
        z.t.mock name=z.io.error

        z.cls.delete object

        z.t.expect.status.is.false

        unset "z_cls_active[$object]"
        $object.count.get

        z.t.expect.reply 3

        z.cls.delete object
      }
    }
  }

  z.t.context "実体がある場合"; {
    z.t.it "コマンドと状態を解放する"; {
      () {
        z.cls.draw DirectDelete
          z.cls.attr count default=0
        z.cls.drew

        local object=""
        z.cls.new DirectDelete object
        REPLY=false

        z.cls.delete object

        z.t.expect.reply false

        z.var.exists "functions[$object.count.get]"

        z.t.expect.status.is.false

        z.hash.count z_cls_instances

        z.t.expect.reply 0
      }
    }
  }

  z.t.context "生成した関数を利用者が上書きした場合"; {
    z.t.it "他の共有本体へ影響せず、削除後も上書きを保持する"; {
      () {
        local first=""
        z.cls.new TestCounter first
        functions[$first.value]='REPLY=replacement'

        $first.increment
        $first.count.get

        z.t.expect.reply 1

        z.cls.delete first
        $first.value

        z.t.expect.reply replacement

        unfunction "$first.value"
      }
    }

    z.t.it "別メソッドの本体をコピーした上書きも削除しない"; {
      () {
        local first=""
        z.cls.new TestCounter first
        functions -c "$first.increment" "$first.value"
        local expected=$functions[$first.value]

        z.cls.delete first

        z.t.expect "${functions[$first.value]-}" "$expected"

        unfunction "$first.value"
      }
    }
  }

  z.t.context "多数の参照を順に削除する場合"; {
    z.t.it "生存中の参照、利用者の関数、再生成に必要な定義を保持する"; {
      () {
        local -a saved_refs=()
        local index

        for (( index=1; index<=72; index++ )); do
          local "owner_$index="
          () {
            local object=""
            z.cls.new TestCounter object || return 1

            z.cls.owner.move from=object "to=owner_$index" || return 1
            saved_refs+=("$REPLY")
          }

          z.t.expect.status.is.true
        done

        local reference

        for reference in "${(@)saved_refs[1,36]}"; do
          z.cls.delete "$reference"

          z.t.expect.status.is.true
        done

        reference=$saved_refs[37]
        "$reference.count.set" 42
        "$reference.value"

        z.t.expect.reply 42

        local replaced="$reference.increment"
        functions[$replaced]='REPLY=custom'

        for reference in "${(@)saved_refs[37,72]}"; do
          z.cls.delete "$reference"

          z.t.expect.status.is.true
        done

        "$replaced"

        z.t.expect.reply custom

        z.var.exists "functions[$reference.value]"

        z.t.expect.status.is.false

        local fresh=""

        z.cls.new TestCounter fresh

        z.t.expect.status.is.true

        $fresh.increment

        z.t.expect.reply 1

        z.cls.delete fresh

        z.t.expect.status.is.true

        unfunction "$replaced"
      }
    }
  }

  z.t.context "削除した参照と同名の変数を別スコープで使う場合"; {
    z.t.it "元のコマンドを解放し、新しい初期状態の実体を作る"; {
      () {
        local first=""
        z.cls.new TestCounter first

        z.cls.new TestCounter first 2>/dev/null

        z.t.expect.status.is.false

        local missing=""

        z.cls.new Missing missing 2>/dev/null

        z.t.expect.status.is.false

        z.cls.delete first

        z.t.expect.status.is.true

        z.var.exists "functions[$first.increment]"

        z.t.expect.status.is.false

        z.var.exists "functions[$first.count.get]"

        z.t.expect.status.is.false

        z.var.exists "functions[$first.count.set]"

        z.t.expect.status.is.false

        () {
          local first=""

          z.cls.new TestCounter first

          z.t.expect.status.is.true

          $first.value

          z.t.expect.reply 0

          z.cls.delete first
        }
      }
    }
  }
}
