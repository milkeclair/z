source ${z_main}

z.t.describe "z.cls.draw"; {
  z.t.context "有効なクラス名の場合"; {
    z.t.it "有効なクラス名で定義を開始する"; {
      z.cls.draw DirectDraw
        z.t.expect "$z_cls_drawing" DirectDraw

      z.cls.abort
    }
  }

  z.t.context "DEBUGトラップが呼出元のresultに代入する場合"; {
    z.t.it "DEBUGトラップの代入で定義開始の終了コードは変わらない"; {
      local -a output=()
      output=("${(@f)$(
        local result=before
        TRAPDEBUG() {
          if [[ $funcstack[2] == z.cls.draw ]]; then
            result=61
          fi
          return 0
        }

        z.cls.draw DebugDraw
        local draw_status=$?
        z.cls.drew
        unfunction TRAPDEBUG
        print -rl -- "$draw_status" "$result"
      )}")

      z.t.expect.status.is.true
      z.t.expect "$output[1]" 0
      z.t.expect "$output[2]" 61
    }
  }

  z.t.context "引数が不足する場合"; {
    z.t.it "クラス名のない定義はdrewで失敗する"; {
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
}

z.t.describe "z.cls.attr"; {
  z.t.context "属性に初期値を指定する場合"; {
    z.t.it "falseを属性の初期値として保存する"; {
      z.cls.draw DirectAttr
        z.cls.attr literal default=false

        z.t.expect "$z_cls_defaults[DirectAttr:literal]" false

      z.cls.abort
    }
  }

  z.t.context "同名属性がある場合"; {
    z.t.it "同名属性の再宣言で元の初期値を上書きしない"; {
      z.cls.draw DuplicateAttr
        z.cls.attr count default=3
        z.t.mock name=z.io.error

        z.cls.attr count default=9

        z.t.expect.status.is.false
        z.t.expect "$z_cls_defaults[DuplicateAttr:count]" 3

      z.cls.abort
    }
  }

  z.t.context "空の初期値を明示した場合"; {
    z.t.it "空の初期値を持つ属性をスカラーとして取得する"; {
      z.cls.draw EmptyDefault
        z.cls.attr default default=
      z.cls.drew

      () {
        local object=""
        z.cls.new EmptyDefault object

        $object.default.get
        local reply_kind=${(t)REPLY}
        local default_value=$REPLY

        z.t.expect "$reply_kind" scalar
        z.t.expect.is.null "$default_value"

        z.cls.delete object
      }
    }
  }

  z.t.context "defaultを属性名より前に置く場合"; {
    z.t.it "先に指定したdefault=の空白と等号を保つ"; {
      z.cls.draw NamedDefault
        z.cls.attr 'default=a b=c' label
      z.cls.drew

      () {
        local named_default=""
        z.cls.new NamedDefault named_default

        $named_default.label.get

        z.t.expect.reply "a b=c"

        z.cls.delete named_default
      }
    }
  }

  z.t.context "defaultを省略した場合"; {
    z.t.it "default=を省略した属性は登録できない"; {
      z.cls.draw MissingDefault
        z.cls.attr value 2>/dev/null # zls: ignore missing-named-argument

        z.t.expect.status.is.false

      z.cls.abort
    }
  }

  z.t.context "defaultを重複して指定した場合"; {
    z.t.it "default=が2つある属性は登録できない"; {
      z.cls.draw DuplicateDefault
        z.cls.attr default=one default=two 2>/dev/null # zls: ignore missing-positional-argument

        z.t.expect.status.is.false

      z.cls.abort
    }
  }
}

z.t.describe "z.cls.method"; {
  z.t.context "本文を第2引数で渡す場合"; {
    z.t.it "第2引数の本文をメソッドとして登録する"; {
      z.cls.draw DirectMethod
        z.cls.method value 'REPLY=literal'

        z.t.expect "$z_cls_bodies[DirectMethod:value]" 'REPLY=literal'

      z.cls.abort
    }
  }

  z.t.context "第2引数が空文字列の場合"; {
    z.t.it "空の本文を持つメソッドを登録する"; {
      z.cls.draw EmptyMethod
        z.cls.method empty ''

        z.hash.has.key z_cls_bodies key=EmptyMethod:empty

        z.t.expect.status.is.true
        z.t.expect.is.null "$z_cls_bodies[EmptyMethod:empty]"

      z.cls.abort
    }
  }

  z.t.context "第2引数を渡しメソッド名が不正な場合"; {
    z.t.it "引用本文の不正なメソッド名はその場で拒否する"; {
      z.cls.draw InvalidQuotedMethod
        z.t.mock name=z.io.error

        z.cls.method bad-name 'REPLY=ignored'

        z.t.expect.status.is.false

      z.cls.abort
    }
  }
}

z.t.describe "z.cls.drew"; {
  z.t.context "定義を開始していない場合"; {
    z.t.it "定義中のクラスがなければ公開に失敗する"; {
      z.cls.abort
      z.t.mock name=z.io.error

      z.cls.drew

      z.t.expect.status.is.false
    }
  }

  z.t.context "定義中のクラスの場合"; {
    z.t.it "定義中のクラスを公開し定義状態を解除する"; {
      z.cls.draw DirectPublish
      z.cls.drew

      z.var.exists "z_cls_classes[DirectPublish]"

      z.t.expect.status.is.true
      z.t.expect.is.null "$z_cls_drawing"
    }
  }

  z.t.context "属性の登録に失敗した場合"; {
    z.t.it "属性の登録に失敗したクラスは公開されない"; {
      z.cls.draw InvalidAttributeClass
        z.cls.attr value 2>/dev/null # zls: ignore missing-named-argument
      z.cls.drew

      z.t.expect.status.is.false

      z.hash.has.key z_cls_classes key=InvalidAttributeClass

      z.t.expect.status.is.false
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

  z.t.context "DEBUGトラップが呼出元のkeyに代入する場合"; {
    z.t.it "トラップの代入を保ち、未公開の定義を破棄する"; {
      local -a output=()
      output=("${(@f)$(
        local key=before
        TRAPDEBUG() {
          if [[ $ZSH_DEBUG_CMD == ': after_abort' ]]; then
            key=other
          fi
          return 0
        }

        z.cls.draw DebugAbort
          z.cls.attr count default=1
          z.cls.method value 'REPLY=old'
        z.cls.abort
        : after_abort
        unfunction TRAPDEBUG
        print -rl -- "$key" "${+z_cls_defaults[DebugAbort:count]}" "${+z_cls_bodies[DebugAbort:value]}"
      )}")

      z.t.expect.status.is.true
      z.t.expect "$output[1]" other
      z.t.expect "$output[2]" 0
      z.t.expect "$output[3]" 0
    }
  }

  z.t.context "未公開の定義がある場合"; {
    z.t.it "初期値と本体を破棄する"; {
      z.cls.draw DirectAbort
        z.cls.attr count default=0
        z.cls.method value '$self.count.get'

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
  z.t.context "参照を変換する変数属性がある場合"; {
    z.t.it "大文字へ変換する変数にはインスタンスを作らない"; {
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

    z.t.it "桁揃えする変数にはインスタンスを作らない"; {
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

        $object.count.get

        z.t.expect.reply 3

        z.cls.delete object

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "代入先の名前がclassの場合"; {
    z.t.it "呼び出し元のclassにインスタンス参照を代入する"; {
      () {
        local class=""
        z.cls.draw ClassBinding
        z.cls.drew

        z.cls.new ClassBinding class

        z.t.expect.includes "$class" z_cls_

        z.cls.delete class
      }
    }
  }

  z.t.context "メソッドが呼び出し元のローカル変数を参照する場合"; {
    z.t.it "resultとcurrent_instanceを呼び出し元から読む"; {
      () {
        local object=""
        local result=caller_result
        local current_instance=caller_instance
        z.cls.draw CallerVariables
          z.cls.method read 'REPLY="${result}:$current_instance"'
        z.cls.drew
        z.cls.new CallerVariables object

        $object.read

        z.t.expect.reply "caller_result:caller_instance"

        z.cls.delete object
      }
    }
  }

  z.t.context "参照をコピーした場合"; {
    z.t.it "コピーから更新した値を元の参照で読める"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        local other=$counter

        $other.increment
        $counter.count.get

        z.t.expect.reply 1

        z.cls.delete counter
      }
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
          z.cls.method increment '$self.count.get || return 1; $self.count.set "$(( REPLY + 1 ))" || return 1; $self.count.get'
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
          z.cls.method increment '$self.__z_cls_value.get || return 1; $self.__z_cls_value.set "$(( REPLY + 1 ))" || return 1; $self.__z_cls_value.get'
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
    z.t.it "インスタンスを作らず失敗する"; {
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
    z.t.it "内側のインスタンスの削除後に外側の状態を保持する"; {
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

    z.t.it "内側と外側の参照をそれぞれのクラスへ解決する"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        $counter.count.set 8

        () {
          local counter=""

          z.cls.draw InnerCounter
            z.cls.attr items default=inner
          z.cls.drew
          z.cls.new InnerCounter counter

          z.t.expect.status.is.true

          $counter.items.get

          z.t.expect.reply inner

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

  z.t.context "呼出元に同名の通常関数がある場合"; {
    z.t.it "通常関数とインスタンスのメソッドを独立して呼び出せる"; {
      () {
        local first=""
        first.value() {
          REPLY=original
        }

        z.cls.new TestCounter first

        z.t.expect.status.is.true

        $first.value

        z.t.expect.reply 0

        first.value

        z.t.expect.reply original

        z.cls.delete first
        unfunction first.value
      }
    }
  }

  z.t.context "生成する名前を先に別の通常関数が使っている場合"; {
    z.t.it "既存の関数と空の代入先を保持する"; {
      () {
        local object=""
        local -i z_cls_next_id=500
        local reference="z_cls_${$}_501"
        functions[$reference.value]='REPLY=original'
        z.t.mock name=z.io.error

        z.cls.new TestCounter object

        z.t.expect.status.is.false
        z.t.expect.is.null "$object"

        "$reference.value"

        z.t.expect.reply original
        z.var.exists "functions[$reference.increment]"

        z.t.expect.status.is.false

        unfunction "$reference.value"
      }
    }
  }

  z.t.context "呼び出し元のIFSがコロンの場合"; {
    z.t.it "各属性を別のコマンドで取得できる"; {
      () {
        local object=""
        local IFS=:

        z.cls.draw ClassWithCustomIFS
          z.cls.attr value default=one
          z.cls.attr other default=two
        z.cls.drew
        z.cls.new ClassWithCustomIFS object

        $object.value.get
        local value=$REPLY
        $object.other.get

        z.t.expect.reply two
        z.t.expect "$value" one

        z.cls.delete object
      }
    }
  }

  z.t.context "GLOB_SUBSTが有効な場合"; {
    z.t.it "インスタンスの削除で生成したgetterを解除する"; {
      () {
        local object=""
        setopt localoptions globsubst

        z.cls.draw ClassWithGlobSubst
          z.cls.attr value default=1
        z.cls.drew
        z.cls.new ClassWithGlobSubst object

        z.cls.delete object
        z.var.exists "functions[$object.value.get]"

        z.t.expect.status.is.false
      }
    }
  }

  z.t.context "作成先を宣言していない場合"; {
    z.t.it "グローバル変数とインスタンスを作らない"; {
      z.t.mock name=z.io.error

      z.cls.new TestCounter missing_counter

      z.t.expect.status.is.false

      z.var.exists missing_counter

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.delete"; {
  z.t.context "コピーした参照を持つ変数を渡した場合"; {
    z.t.it "元の参照で使っていたコマンドを解除する"; {
      () {
        local counter=""
        z.cls.new TestCounter counter
        local other=$counter

        z.cls.delete other
        z.var.exists "functions[$counter.value]"

        z.t.expect.status.is.false
      }
    }
  }

  z.t.context "errexitが有効な場合"; {
    z.t.it "インスタンスを登録表から削除する"; {
      (
        setopt errexit
        local counter=""
        z.cls.new TestCounter counter
        $counter.increment

        z.cls.delete counter

        ! z.var.exists "z_cls_instances[$counter]"
      )

      z.t.expect.status.is.true
    }

    z.t.it "インスタンスのコマンドを解除する"; {
      (
        setopt errexit
        local counter=""
        z.cls.new TestCounter counter
        $counter.increment

        z.cls.delete counter

        ! z.var.exists "functions[$counter.increment]"
      )

      z.t.expect.status.is.true
    }
  }

  z.t.context "実行中のインスタンスの場合"; {
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

  z.t.context "インスタンスがある場合"; {
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
    z.t.it "削除後にユーザーが上書きした関数を残す"; {
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

    z.t.it "別メソッドからコピーした上書きを残す"; {
      () {
        local first=""
        z.cls.new TestCounter first
        functions -c "$first.increment" "$first.value"
        local expected=$functions[$first.value]

        z.cls.delete first

        z.t.expect "${functions[$first.value]}" "$expected"

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

        $fresh.increment

        z.t.expect.reply 1

        z.cls.delete fresh

        z.t.expect.status.is.true

        unfunction object.increment
      }
    }
  }

  z.t.context "削除した参照と同名の変数を別スコープで使う場合"; {
    z.t.it "元のコマンドを解放し、新しい初期状態のインスタンスを作る"; {
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
