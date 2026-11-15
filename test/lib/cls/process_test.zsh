source ${z_main}

z.t.describe "z.cls"; {
  z.t.context "sourceでクラスを定義する場合"; {
    z.t.it "大量削除後も生存中の参照とクラス定義、ユーザー関数を保持する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" cleanup-recreate
      z.t.expect.status.is.true
    }
    z.t.it "本体の実行を保留し、制御構文と呼出元の変数を保つ"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" capture
      z.t.expect.status.is.true
    }
    z.t.it "インスタンスごとに属性を保存し、get/setとメソッドで共有する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" state
      z.t.expect.status.is.true
    }
    z.t.it "同一インスタンスのメソッド間で状態を共有する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" nested
      z.t.expect.status.is.true
    }
    z.t.it "明示return後も状態、REPLY、終了ステータスを保つ"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" result
      z.t.expect.status.is.true
    }
    z.t.it "既存の関数形式DEBUGトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" function-trap
      z.t.expect.status.is.true
    }
    z.t.it "既存のリスト形式DEBUGトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" list-trap
      z.t.expect.status.is.true
    }
    z.t.it "再代入を拒否し、削除後は別スコープの同名変数を使える"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" lifecycle
      z.t.expect.status.is.true
    }
    z.t.it "既存関数との衝突時に部分的なインスタンスを残さない"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" collision
      z.t.expect.status.is.true
    }
    z.t.it "localoptionsの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" options localoptions
      z.t.expect.status.is.true
    }
    z.t.it "localtrapsの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" options localtraps
      z.t.expect.status.is.true
    }
    z.t.it "nodebugbeforecmdの設定を保持して定義する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" options nodebugbeforecmd
      z.t.expect.status.is.true
    }
    z.t.it "終了マーカーがない定義を破棄してトラップを復元する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" missing-end
      z.t.expect.status.is.true
    }
    z.t.it "メソッド内で作った配列を要素のまま保存する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" arrays
      z.t.expect.status.is.true
    }
    z.t.it "無効なメソッド名の本体を実行せず定義を破棄する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" invalid-header
      z.t.expect.status.is.true
    }
    z.t.it "パイプ、ヒアドキュメント、条件付きコマンドを保存する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" body-syntax
      z.t.expect.status.is.true
    }
    z.t.it "複数のシェル設定が同時に有効でも動作する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" options localoptions,localtraps,nodebugbeforecmd
      z.t.expect.status.is.true
    }
    z.t.it "標準出力へ表示するDEBUGトラップも復元する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" noisy-list-trap >/dev/null
      z.t.expect.status.is.true
    }
    z.t.it "local変数で同名インスタンスを隠し、外側の状態を保持する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" scopes
      z.t.expect.status.is.true
    }
    z.t.it "内側の同名変数が別クラスを指す場合も正しく呼び分ける"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" different-class-scope
      z.t.expect.status.is.true
    }
    z.t.it "コピーした参照は同じ実体を指し、どちらの更新も見える"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" pointers
      z.t.expect.status.is.true
    }
    z.t.it "参照の直接代入と再生成を拒否し、属性の更新は許可する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" reassignment
      z.t.expect.status.is.true
    }
    z.t.it "errexitが有効でも生成した関数と状態を削除する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" errexit-cleanup
      z.t.expect.status.is.true
    }
    z.t.it "整数の基数、浮動小数、連想配列、属性付き配列と未設定状態を保存する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" typed-state
      z.t.expect.status.is.true
    }
    z.t.it "整数setterの式が同じインスタンスの属性を参照できる"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" arithmetic-setter
      z.t.expect.status.is.true
    }
    z.t.it "共有した本体の一つを上書きしても他へ影響せず、上書きを削除しない"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" preserve-overrides
      z.t.expect.status.is.true
    }
    z.t.it "functionargzeroが無効でも呼び出した名前から正しく処理する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" options nofunctionargzero
      z.t.expect.status.is.true
    }
    z.t.it "別メソッドの本体をコピーしたユーザーの上書きも保護する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" preserve-copied-overrides
      z.t.expect.status.is.true
    }
    z.t.it "allexport環境の子シェルでも独立して初期化する"; {
      zsh -f "$z_root/test/lib/cls/scenarios.zsh" exported-environment
      z.t.expect.status.is.true
    }
  }
}
