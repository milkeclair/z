source ${z_main}

# 定義読込時のトラップ設定を初期化のスコープに閉じ込める。
() {
  setopt localoptions localtraps
  source "$z_root/test/lib/cls/counter.zsh"
  source "$z_root/test/lib/cls/arrays.zsh"
}

z.t.describe "z.clsの実体参照"; {
  z.t.context "内側のスコープに同名localがある場合"; {
    z.t.it "内側の実体を削除しても外側の参照と状態を保持する"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        local outer_id=$counter
        counter.count.set 10

        () {
          local counter=""

          z.cls.new TestCounter counter

          z.t.expect.status.is.true
          z.t.expect.not "$counter" "$outer_id"

          counter.increment
          counter.count.get

          z.t.expect.reply 1

          z.cls.delete counter

          z.t.expect.status.is.true
        }

        z.t.expect "$counter" "$outer_id"

        counter.count.get

        z.t.expect.reply 10

        z.cls.delete counter
        z.var.exists 'functions[counter.increment]'

        z.t.expect.status.is.false
      }
    }

    z.t.it "内側の参照が別クラスを指す場合も呼び分ける"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        counter.count.set 8

        () {
          local counter=""

          z.cls.new ArrayBox counter

          z.t.expect.status.is.true

          counter.fill
          counter.items.get
          local item_count=${#REPLY}

          z.t.expect "$item_count" 3

          counter.count.get 2>/dev/null

          z.t.expect.status.is.false

          z.cls.delete counter
        }

        counter.count.get

        z.t.expect.reply 8

        z.cls.delete counter
      }
    }
  }

  z.t.context "生成した関数を利用者が上書きした場合"; {
    z.t.it "他の共有本体へ影響せず、削除後も上書きを保持する"; {
      () {
        local first=""
        z.cls.new TestCounter first
        first.value() {
          REPLY=replacement
        }

        first.increment
        first.count.get

        z.t.expect.reply 1

        z.cls.delete first
        first.value

        z.t.expect.reply replacement

        unfunction first.value
      }
    }

    z.t.it "別メソッドの本体をコピーした上書きも削除しない"; {
      () {
        local first=""
        z.cls.new TestCounter first
        functions -c first.increment first.value
        local expected=$functions[first.value]

        z.cls.delete first

        z.t.expect "${functions[first.value]-}" "$expected"

        unfunction first.value
      }
    }
  }

  z.t.context "多数の参照を順に削除する場合"; {
    z.t.it "生存中の参照、利用者の関数、再生成に必要な定義を保持する"; {
      () {
        local -a saved_refs=()
        local index

        for (( index=1; index<=72; index++ )); do
          () {
            local object=""

            z.cls.new TestCounter object

            z.t.expect.status.is.true

            saved_refs+=("$object")
          }
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

        object.increment() {
          REPLY=custom
        }

        for reference in "${(@)saved_refs[37,72]}"; do
          z.cls.delete "$reference"

          z.t.expect.status.is.true
        done

        object.increment

        z.t.expect.reply custom

        z.var.exists "functions[$reference.value]"

        z.t.expect.status.is.false

        local fresh=""

        z.cls.new TestCounter fresh

        z.t.expect.status.is.true

        fresh.increment

        z.t.expect.reply 1

        z.cls.delete fresh

        z.t.expect.status.is.true

        unfunction object.increment
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

        z.var.exists 'functions[first.increment]'

        z.t.expect.status.is.false

        z.var.exists 'functions[first.count.get]'

        z.t.expect.status.is.false

        z.var.exists 'functions[first.count.set]'

        z.t.expect.status.is.false

        () {
          local first=""

          z.cls.new TestCounter first

          z.t.expect.status.is.true

          first.value

          z.t.expect.reply 0

          z.cls.delete first
        }
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

        counter.count.set 3
        counter.increment

        z.t.expect.reply 4

        z.cls.delete counter
      }
    }
  }

  z.t.context "作成先のコマンド名に既存の関数がある場合"; {
    z.t.it "既存の関数を保ち、実体のコマンドを部分的に残さない"; {
      first.value() {
        REPLY=original
      }

      z.cls.new TestCounter first 2>/dev/null

      z.t.expect.status.is.false

      first.value

      z.t.expect.reply original

      z.var.exists 'functions[first.increment]'

      z.t.expect.status.is.false

      unfunction first.value
    }
  }
}
