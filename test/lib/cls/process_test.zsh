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

      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.attr"; {
  z.t.context "定義中の属性の場合"; {
    z.t.it "defaultを保持する"; {
      z.cls.draw DirectAttr

      z.cls.attr literal false

      z.t.expect "$z_cls_defaults[DirectAttr:literal]" false
      z.cls.abort
    }
  }

  z.t.context "同名属性がある場合"; {
    z.t.it "上書きを拒否する"; {
      z.cls.draw DuplicateAttr
      z.cls.attr count 3
      z.t.mock name=z.io.error

      z.cls.attr count 9

      z.t.expect.status.is.false
      z.t.expect "$z_cls_defaults[DuplicateAttr:count]" 3
      z.cls.abort
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
      z.t.expect "$z_cls_drawing" ''
    }
  }
}

z.t.describe "z.cls.abort"; {
  z.t.context "呼出元にreadonly argがある場合"; {
    z.t.it "呼出元を変更せずに定義を破棄する"; {
      local -A observations=()
      z.cls.draw ReadonlyAbort
      z.cls.attr count 0

      () {
        local -r arg=untouched
        z.cls.abort
        observations[status]=$?
        observations[arg]=$arg
      }

      z.t.expect "$observations[status]" 0
      z.t.expect "$observations[arg]" untouched
      z.t.expect "$z_cls_drawing" ''
    }
  }

  z.t.context "未公開の定義がある場合"; {
    z.t.it "defaultと本体を破棄する"; {
      z.cls.draw DirectAbort
      z.cls.attr count 0
      z.cls.fn value 'REPLY=$count'

      z.cls.abort

      z.t.expect "$z_cls_drawing" ''
      z.var.exists 'z_cls_defaults[DirectAbort:count]'
      z.t.expect.status.is.false
      z.var.exists 'z_cls_bodies[DirectAbort:value]'
      z.t.expect.status.is.false
    }
  }
}

z.t.describe "z.cls.new"; {
  z.t.context "argを参照名として使う場合"; {
    z.t.it "readonly化した参照を返し、取得と削除ができる"; {
      local -A observations=()
      z.cls.draw ArgumentBinding
      z.cls.attr count 3
      z.cls.drew

      () {
        local arg
        z.cls.new ArgumentBinding arg
        observations[created]=$?
        arg.count.get
        observations[value]=$REPLY
        z.cls.delete arg
        observations[deleted]=$?
      }

      z.t.expect "$observations[created]" 0
      z.t.expect "$observations[value]" 3
      z.t.expect "$observations[deleted]" 0
    }
  }

  z.t.context "呼出元に別のreadonly argがある場合"; {
    z.t.it "既存の変数を変えずに生成と削除ができる"; {
      local -A observations=()
      z.cls.draw ReadonlyArgument
      z.cls.attr count 7
      z.cls.drew

      () {
        local -r arg=untouched
        local object
        z.cls.new ReadonlyArgument object
        observations[created]=$?
        object.count.get
        observations[value]=$REPLY
        z.cls.delete object
        observations[deleted]=$?
        observations[arg]=$arg
      }

      z.t.expect "$observations[created]" 0
      z.t.expect "$observations[value]" 7
      z.t.expect "$observations[deleted]" 0
      z.t.expect "$observations[arg]" untouched
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
        local object
        z.cls.draw DirectNew
        z.cls.attr count 0
        z.cls.drew

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
        local object
        z.cls.draw ActiveDelete
        z.cls.attr count 3
        z.cls.drew
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
        local object
        z.cls.draw DirectDelete
        z.cls.attr count 0
        z.cls.drew
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

z.t.describe "z.cls source integration"; {
  z.t.context "sourceでクラスを定義する場合"; {

    z.t.it "大量削除後も生存中の参照とクラス定義、ユーザー関数を保持する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" cleanup-recreate

      z.t.expect.status.is.true
    }

    z.t.it "本体の実行を保留し、制御構文と呼出元の変数を保つ"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" capture

      z.t.expect.status.is.true
    }

    z.t.it "インスタンスごとに属性を保存し、get/setとメソッドで共有する"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" state

      z.t.expect.status.is.true
    }

    z.t.it "同一インスタンスのメソッド間で状態を共有する"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" nested

      z.t.expect.status.is.true
    }

    z.t.it "明示return後も状態、REPLY、終了ステータスを保つ"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" result

      z.t.expect.status.is.true
    }

    z.t.it "既存の関数形式DEBUGトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" function-trap

      z.t.expect.status.is.true
    }

    z.t.it "既存のリスト形式DEBUGトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" list-trap

      z.t.expect.status.is.true
    }

    z.t.it "再代入を拒否し、削除後は別スコープの同名変数を使える"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" lifecycle

      z.t.expect.status.is.true
    }

    z.t.it "既存関数との衝突時に部分的なインスタンスを残さない"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" collision

      z.t.expect.status.is.true
    }

    z.t.it "localoptionsの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" options localoptions

      z.t.expect.status.is.true
    }

    z.t.it "localtrapsの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" options localtraps

      z.t.expect.status.is.true
    }

    z.t.it "nodebugbeforecmdの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" options nodebugbeforecmd

      z.t.expect.status.is.true
    }

    z.t.it "終了マーカーがない定義を破棄してトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" missing-end

      z.t.expect.status.is.true
    }

    z.t.it "メソッド内で作った配列を要素のまま保存する"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" arrays

      z.t.expect.status.is.true
    }

    z.t.it "無効なメソッド名の本体を実行せず定義を破棄する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" invalid-header

      z.t.expect.status.is.true
    }

    z.t.it "パイプ、ヒアドキュメント、条件付きコマンドを保存する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" body-syntax

      z.t.expect.status.is.true
    }

    z.t.it "複数のシェル設定が同時に有効でも動作する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" options localoptions,localtraps,nodebugbeforecmd

      z.t.expect.status.is.true
    }

    z.t.it "標準出力へ表示するDEBUGトラップも復元する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" noisy-list-trap >/dev/null

      z.t.expect.status.is.true
    }

    z.t.it "local変数で同名インスタンスを隠し、外側の状態を保持する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" scopes

      z.t.expect.status.is.true
    }

    z.t.it "内側の同名変数が別クラスを指す場合も正しく呼び分ける"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" different-class-scope

      z.t.expect.status.is.true
    }

    z.t.it "コピーした参照は同じ実体を指し、どちらの更新も見える"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" pointers

      z.t.expect.status.is.true
    }

    z.t.it "参照の直接代入と再生成を拒否し、属性の更新は許可する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" reassignment

      z.t.expect.status.is.true
    }

    z.t.it "errexitが有効でも生成した関数と状態を削除する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" errexit-cleanup

      z.t.expect.status.is.true
    }

    z.t.it "整数の基数、浮動小数、連想配列、属性付き配列と未設定状態を保存する"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" typed-state

      z.t.expect.status.is.true
    }

    z.t.it "整数setterの式が同じインスタンスの属性を参照できる"; {
      zsh -f "$z_root/test/lib/cls/attribute-scenarios.zsh" arithmetic-setter

      z.t.expect.status.is.true
    }

    z.t.it "共有した本体の一つを上書きしても他へ影響せず、上書きを削除しない"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" preserve-overrides

      z.t.expect.status.is.true
    }

    z.t.it "functionargzeroが無効でも呼び出した名前から正しく処理する"; {
      zsh -f "$z_root/test/lib/cls/source-scenarios.zsh" options nofunctionargzero

      z.t.expect.status.is.true
    }

    z.t.it "別メソッドの本体をコピーしたユーザーの上書きも保護する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" preserve-copied-overrides

      z.t.expect.status.is.true
    }

    z.t.it "allexport環境の子シェルでも独立して初期化する"; {
      zsh -f "$z_root/test/lib/cls/reference-scenarios.zsh" exported-environment

      z.t.expect.status.is.true
    }
  }
}
