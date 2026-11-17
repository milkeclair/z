source ${z_main}

z.t.describe "z.cls.draw"; {
  z.t.context "有効なクラス名の場合"; {
    z.t.it "定義を開始する"; {
      z.cls.draw DirectDraw; {
        z.t.expect "$z_cls_drawing" DirectDraw

        z.cls.abort
      }
    }
  }

  z.t.context "引数が不足する場合"; {
    z.t.it "失敗する"; {
      z.t.mock name=z.io.error

      z.cls.draw # zls: ignore

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.attr"; {
  z.t.context "定義中の属性の場合"; {
    z.t.it "初期値を保持する"; {
      z.cls.draw DirectAttr; {
        z.cls.attr literal false

        z.t.expect "$z_cls_defaults[DirectAttr:literal]" false

        z.cls.abort
      }
    }
  }

  z.t.context "同名属性がある場合"; {
    z.t.it "上書きを拒否する"; {
      z.cls.draw DuplicateAttr; {
        z.cls.attr count 3
        z.t.mock name=z.io.error

        z.cls.attr count 9

        z.t.expect.status.is.false
        z.t.expect "$z_cls_defaults[DuplicateAttr:count]" 3

        z.cls.abort
      }
    }
  }
}

z.t.describe "z.cls.fn"; {
  z.t.context "明示的な本体の場合"; {
    z.t.it "クラスへ登録する"; {
      z.cls.draw DirectMethod; {
        z.cls.fn value 'REPLY=literal'

        z.t.expect "$z_cls_bodies[DirectMethod:value]" 'REPLY=literal'

        z.cls.abort
      }
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
      z.cls.draw DirectPublish; {
        z.cls.drew
      }

      z.t.expect "$z_cls_classes[DirectPublish]" 1
      z.t.expect.is.null "$z_cls_drawing"
    }
  }
}

z.t.describe "z.cls.abort"; {
  z.t.context "呼出元にreadonly argがある場合"; {
    z.t.it "呼出元を変更せずに定義を破棄する"; {
      z.cls.draw ReadonlyAbort; {
        z.cls.attr count 0

        () {
          local -r arg=untouched

          z.cls.abort

          z.t.expect.status.is.true
          z.t.expect "$arg" untouched
        }

        z.t.expect.is.null "$z_cls_drawing"
      }
    }
  }

  z.t.context "未公開の定義がある場合"; {
    z.t.it "初期値と本体を破棄する"; {
      z.cls.draw DirectAbort; {
        z.cls.attr count 0
        z.cls.fn value 'REPLY=$count'

        z.cls.abort
      }

      z.t.expect.is.null "$z_cls_drawing"

      z.var.exists 'z_cls_defaults[DirectAbort:count]'

      z.t.expect.status.is.false

      z.var.exists 'z_cls_bodies[DirectAbort:value]'

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.new"; {
  z.t.context "変換すると意味が変わる名前と属性値の場合"; {
    z.t.it "falseというクラス名とnullという文字列を保つ"; {
      () {
        z.cls.draw false; {
          z.cls.attr literal null
          z.cls.drew
        }

        local object=""

        z.cls.new false object
        object.literal.get

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
        z.cls.draw ScopedInternals; {
          z.cls.attr count 0
          z.cls.fn increment '(( ++count )); REPLY=$count'
          z.cls.drew
        }

        local object=""
        z.cls.new ScopedInternals object
        object.increment

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
        z.cls.draw FormerPrefix; {
          z.cls.attr __z_cls_value 0
          z.cls.fn increment '(( ++__z_cls_value )); REPLY=$__z_cls_value'
          z.cls.drew
        }

        local object=""
        z.cls.new FormerPrefix object

        object.increment

        z.t.expect.reply 1

        object.__z_cls_value.get

        z.t.expect.reply 1

        z.cls.delete object

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "argを参照名として使う場合"; {
    z.t.it "readonly化した参照を返し、取得と削除ができる"; {
      z.cls.draw ArgumentBinding; {
        z.cls.attr count 3
        z.cls.drew
      }

      () {
        local arg=""

        z.cls.new ArgumentBinding arg

        z.t.expect.status.is.true

        arg.count.get

        z.t.expect.reply 3

        z.cls.delete arg

        z.t.expect.status.is.true
      }
    }
  }

  z.t.context "呼出元に別のreadonly argがある場合"; {
    z.t.it "既存の変数を変えずに生成と削除ができる"; {
      z.cls.draw ReadonlyArgument; {
        z.cls.attr count 7
        z.cls.drew
      }

      () {
        local -r arg=untouched
        local object=""

        z.cls.new ReadonlyArgument object

        z.t.expect.status.is.true

        object.count.get

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
        z.cls.draw DirectNew; {
          z.cls.attr count 0
          z.cls.drew
        }

        local object=""
        z.cls.new DirectNew object

        z.t.expect.reply "$object"
        z.t.expect.includes "$parameters[object]" readonly

        object.count.get

        z.t.expect.reply 0

        z.cls.delete object
      }
    }
  }
}

z.t.describe "z.cls.delete"; {
  z.t.context "実行中の実体の場合"; {
    z.t.it "状態を保持して削除を拒否する"; {
      () {
        z.cls.draw ActiveDelete; {
          z.cls.attr count 3
          z.cls.drew
        }

        local object=""
        z.cls.new ActiveDelete object
        z_cls_active[$object]=1
        z.t.mock name=z.io.error

        z.cls.delete object

        z.t.expect.status.is.false

        unset "z_cls_active[$object]"
        object.count.get

        z.t.expect.reply 3

        z.cls.delete object
      }
    }
  }

  z.t.context "実体がある場合"; {
    z.t.it "コマンドと状態を解放する"; {
      () {
        z.cls.draw DirectDelete; {
          z.cls.attr count 0
          z.cls.drew
        }

        local object=""
        z.cls.new DirectDelete object
        REPLY=false

        z.cls.delete object

        z.t.expect.reply false

        z.var.exists 'functions[object.count.get]'

        z.t.expect.status.is.false

        z.hash.count z_cls_instances

        z.t.expect.reply 0
      }
    }
  }
}

z.t.describe "z.clsの公開API"; {
  z.t.context "補完の関数名キャッシュを構築する場合"; {
    z.t.it "公開DSLの8関数だけを候補にする"; {
      source "$z_root/mod/completion/function/is/operator.zsh"
      source "$z_root/mod/completion/cache/build/process.zsh"
      local -a z_completion_function_names=()
      local function_name=""

      z.completion.cache.build._names

      local -a class_names=()

      for function_name in "${z_completion_function_names[@]}"; do
        z.str.start_with "$function_name" z.cls. && class_names+=("$function_name")
      done

      REPLY=("${class_names[@]}")

      z.t.expect.reply.is.arr z.cls.abort z.cls.attr z.cls.delete z.cls.draw z.cls.drew z.cls.fn z.cls.fn.done z.cls.new
    }
  }
}
