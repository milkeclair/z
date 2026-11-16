# z.reload

現在のシェルで`$HOME/.zshrc`を読み直します。

## インストール

```zsh
z.install.mod reload
```

## 使い方

```zsh
z.reload
```

`source "$HOME/.zshrc"`を実行し、設定の出力・`REPLY`・終了コードを保ちます。ファイルがなければZshがエラーを表示し、終了コード127を返します。`ZDOTDIR`が設定されていても、常に`$HOME/.zshrc`を使います。シェルの状態は、関数内でファイルをsourceする通常の規則に従います。
