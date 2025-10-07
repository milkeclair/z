# z ライブラリ クイックリファレンス

## 📋 目次

- [モジュール概要](#モジュール概要)
- [関数一覧](#関数一覧)
- [使用パターン](#使用パターン)
- [REPLY パターン](#reply-パターン)
- [テストの書き方](#テストの書き方)

## モジュール概要

| モジュール | 種類 | 主な機能 |
|-----------|------|---------|
| **arg** | analysis, operator, process | 引数の取得・検証・処理 |
| **arr** | analysis, operator, process | 配列のカウント・検証・結合 |
| **common** | dsl, operator, wrap | 基本的な演算子と DSL |
| **debug** | process | インタラクティブデバッガ |
| **dir** | operator, process | ディレクトリの検証・作成 |
| **file** | operator, process | ファイルの検証・作成 |
| **int** | operator | 整数の演算・比較 |
| **io** | process | 入出力処理 |
| **str** | color, operator, process | 文字列操作・カラー出力 |
| **t** | dsl, process | テストフレームワーク |

## 関数一覧

### 📦 arr (配列)

```zsh
# analysis - REPLY に結果を返す
z.arr.count <elements...>        # 配列の要素数

# operator - 真偽値を返す
z.arr.is_empty <elements...>     # 配列が空か
z.arr.is_not_empty <elements...> # 配列が空でないか
z.arr.has <value> <elements...>  # 要素を含むか
z.arr.has_not <value> <array...> # 要素を含まないか

# process - REPLY に結果を返す
z.arr.join <elements...>         # 配列を結合
```

### 🔢 int (整数)

```zsh
# operator - 真偽値を返す
z.int.is <value>              # 整数か
z.int.is_not <value>          # 整数でないか
z.int.eq <a> <b>              # a == b
z.int.not_eq <a> <b>          # a != b
z.int.gt <a> <b>              # a > b
z.int.gteq <a> <b>            # a >= b
z.int.lt <a> <b>              # a < b
z.int.lteq <a> <b>            # a <= b
z.int.is_zero <value>         # 0 か
z.int.is_not_zero <value>     # 0 でないか
z.int.is_positive <value>     # 正の数か
z.int.is_negative <value>     # 負の数か
```

### 📝 str (文字列)

```zsh
# process - REPLY に結果を返す
z.str.indent <level> <str>         # インデント追加
z.str.split <str> [delimiter]      # 文字列分割 (デフォルト: "|")
z.str.gsub <str> <search> <replace> # グローバル置換

# color - REPLY に結果を返す
z.str.color.red <str>     # 赤色
z.str.color.green <str>   # 緑色
z.str.color.yellow <str>  # 黄色
z.str.color.blue <str>    # 青色
z.str.color.magenta <str> # マゼンタ
z.str.color.cyan <str>    # シアン

# operator - 真偽値を返す
z.str.is_path_like <str>  # パスっぽい文字列か
```

### 💬 io (入出力)

```zsh
# process
z.io <args...>             # 標準出力
z.io.error <args...>       # 標準エラー出力
z.io.empty                 # 空行出力
z.io.oneline <args...>     # 改行なし出力
z.io.clear                 # 画面クリア
z.io.null [command...]     # 出力を破棄
z.io.read                  # 標準入力から読み取り (REPLY に格納)
```

### ✅ common (共通)

```zsh
# operator - 真偽値を返す
z.is_true <value>      # "true" または 0
z.is_false <value>     # "false" または 1
z.is_truthy <value>    # 真っぽい値
z.is_falsy <value>     # 偽っぽい値
z.eq <a> <b>           # a == b
z.not_eq <a> <b>       # a != b
z.is_null <value>      # 空文字列か
z.is_not_null <value>  # 非空文字列か

# wrap - REPLY に結果を返す
z.return <value>       # 値を正規化して返す

# dsl
z.group [name]         # グループ化
z.guard                # ガード節
```

### 📁 file / dir

```zsh
# file operator - 真偽値を返す
z.file.is <path>       # ファイルが存在するか
z.file.is_not <path>   # ファイルが存在しないか

# file process - REPLY に結果を返す
z.file.create <path>   # ファイル作成

# dir operator - 真偽値を返す
z.dir.is <path>        # ディレクトリが存在するか
z.dir.is_not <path>    # ディレクトリが存在しないか

# dir process - REPLY に結果を返す
z.dir.create <path>    # ディレクトリ作成
```

### 🔧 arg (引数)

```zsh
# analysis - REPLY に結果を返す
z.arg.get <index> <args...>    # 指定位置の引数取得
z.arg.first <args...>          # 最初の引数取得

# operator - 真偽値を返す
z.arg.has <count> <args...>    # 引数数が一致するか
z.arg.has_any <args...>        # 引数が1つ以上あるか
z.arg.has_not_any <args...>    # 引数が0個か

# process - REPLY に結果を返す
z.arg.as <arg> <pattern> <default> # パターンマッチして値取得
```

### 🐛 debug (デバッグ)

```zsh
# process
z.debug                # デバッガ起動
z.debug.enable         # デバッグモード有効化
z.debug.disable        # デバッグモード無効化

# デバッガコマンド:
# c, continue - 継続
# p <var>     - 変数表示
# h, help     - ヘルプ
# q, quit     - 終了
```

### 🧪 t (テスト)

```zsh
# dsl
z.t.describe <description>  # テストグループ
z.t.context <context>       # コンテキスト
z.t.it <description>        # テストケース

# アサーション
z.t.expect <actual> <expected>       # 等価性チェック
z.t.expect_include <text> <substr>   # 部分文字列チェック
z.t.expect_reply <expected>          # REPLY チェック
z.t.expect_reply.arr <elements...>   # REPLY 配列チェック
z.t.expect_status.true               # 終了ステータスチェック

# スキップ
z.t.xdescribe <description> # describeをスキップ
z.t.xcontext <context>      # contextをスキップ
z.t.xit <description>       # itをスキップ

# テスト実行
z.t                  # すべてのテスト実行
z.t <name>           # 特定のテスト実行
z.t -f, --failed     # 失敗したテストのみ表示
z.t -l, --log        # すべてのログ表示
```

## 使用パターン

### パターン1: 条件分岐

```zsh
z.arr.count $@
if z.int.gt $REPLY 2; then
  z.io "3個以上の引数"
else
  z.io "2個以下の引数"
fi
```

### パターン2: ガード節

```zsh
my_function() {
  z.guard; {
    z.arg.has_not_any $@ && return 1
    z.is_null $1 && return 1
  }
  
  # メイン処理
  z.io "処理中: $1"
}
```

### パターン3: 配列処理

```zsh
local -a items=("apple" "banana" "cherry")
z.arr.count $items
z.io "要素数: $REPLY"

z.arr.join $items
z.io "結合: $REPLY"
```

### パターン4: 文字列処理

```zsh
z.str.split "a|b|c" "|"
local -a parts=($REPLY)

z.str.indent 2 "Hello"
z.io $REPLY  # "    Hello"

z.str.gsub "Hello World" "World" "Zsh"
z.io $REPLY  # "Hello Zsh"
```

### パターン5: 整数比較

```zsh
local count=5

if z.int.gt $count 3; then
  z.io "3より大きい"
fi

z.int.is_positive $count && z.io "正の数"
z.int.is_zero $count || z.io "0ではない"
```

## REPLY パターン

### 基本的な使い方

```zsh
# 分析関数は REPLY に結果を格納
z.arr.count "a" "b" "c"
local count=$REPLY  # count = 3

# 処理関数も REPLY に結果を格納
z.str.indent 2 "text"
local indented=$REPLY  # indented = "  text"
```

### チェーンパターン

```zsh
# 関数を連鎖させる
z.arr.count $@
z.int.gt $REPLY 2

# または
z.str.split "a|b|c" "|"
z.arr.count $REPLY
z.io "要素数: $REPLY"
```

### REPLY の保存

```zsh
# REPLY を別の変数に保存してから次の関数を呼ぶ
z.arr.count $array1
local count1=$REPLY

z.arr.count $array2
local count2=$REPLY

z.int.gt $count1 $count2 && z.io "array1の方が大きい"
```

## テストの書き方

### 基本構造

```zsh
source ${z_main}

z.t.describe "テスト対象の関数名"; {
  z.t.context "条件や状況"; {
    z.t.it "期待される動作"; {
      # テストコード
      
      # アサーション
      z.t.expect $actual $expected
    }
  }
}
```

### 具体例

```zsh
source ${z_main}

z.t.describe "z.arr.count"; {
  z.t.context "配列に要素がある場合"; {
    z.t.it "要素数をREPLYに返す"; {
      z.arr.count "a" "b" "c"
      z.t.expect_reply 3
    }
  }

  z.t.context "配列が空の場合"; {
    z.t.it "0をREPLYに返す"; {
      z.arr.count
      z.t.expect_reply 0
    }
  }
}
```

### エラー出力のテスト

```zsh
z.t.it "エラーメッセージを出力する"; {
  local out=$(my_function 2> /dev/null)
  local err=$(my_function 2>&1 1> /dev/null)
  
  z.t.expect $out ""
  z.t.expect_include $err "エラー"
}
```

### 配列のテスト

```zsh
z.t.it "配列を返す"; {
  z.str.split "a|b|c" "|"
  z.t.expect_reply.arr "a" "b" "c"
}
```

## 実践例

### 例1: ファイルチェッカー

```zsh
check_files() {
  z.guard; {
    z.arg.has_not_any $@ && {
      z.io.error "ファイルを指定してください"
      return 1
    }
  }
  
  for file in $@; do
    if z.file.is $file; then
      z.str.color.green "✓ $file"
      z.io $REPLY
    else
      z.str.color.red "✗ $file"
      z.io $REPLY
    fi
  done
}
```

### 例2: 配列フィルター

```zsh
filter_integers() {
  local -a result=()
  
  for item in $@; do
    z.int.is $item && result+=($item)
  done
  
  z.arr.join $result
  echo $REPLY
}
```

### 例3: 設定ファイルパーサー

```zsh
parse_config() {
  local file=$1
  
  z.guard; {
    z.file.is_not $file && {
      z.io.error "設定ファイルが見つかりません: $file"
      return 1
    }
  }
  
  while IFS= read -r line; do
    z.str.split "$line" "="
    local -a parts=($REPLY)
    
    z.arr.count $parts
    z.int.eq $REPLY 2 && {
      local key=${parts[1]}
      local value=${parts[2]}
      z.io "設定: $key = $value"
    }
  done < $file
}
```

## 環境変数

| 変数 | 説明 | デフォルト |
|------|------|----------|
| `Z_ROOT` | インストールディレクトリ | `~/.z` |
| `Z_TEST_ROOT` | テストディレクトリ | `$Z_ROOT/test` |
| `Z_DEBUG` | デバッグモード | `1` (無効) |
| `z_mode` | 実行モード | - |

## インストール/アンインストール

```zsh
# インストール
curl -sL https://raw.githubusercontent.com/milkeclair/z/main/install.zsh | zsh

# または
z.install

# アンインストール
z.uninstall
```

## さらに詳しく

- 📖 [REPOSITORY_ANALYSIS.md](REPOSITORY_ANALYSIS.md) - 詳細な設計分析
- 🔧 [TECHNICAL_INSIGHTS.md](TECHNICAL_INSIGHTS.md) - 実装の技術的詳細
- 📊 [ARCHITECTURE_DIAGRAMS.md](ARCHITECTURE_DIAGRAMS.md) - 視覚的な構造図解

---

**ヒント**: この関数リファレンスをブックマークして、z ライブラリを使う際の辞書として活用してください！
