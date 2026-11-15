source ${z_main}

z.t.describe "z.pj.name.is.valid"; {
  z.t.context "登録ファイル名に使える名前"; {
    z.t.it "文字・数字・アンダースコア・ハイフン・ドットを受け入れる"; {
      for name in some_project project-2 example.test 0 true false _private; do
        z.pj.name.is.valid "$name"
        z.t.expect.status.is.true
      done
    }
  }
  z.t.context "空名・パス・空白を含む名前"; {
    z.t.it "登録範囲の外を指定できない"; {
      for name in "" . .. ../outside /absolute 'has space' 'a/b' '-option' '$(touch marker)' $'a\nb'; do
        z.pj.name.is.valid "$name"
        z.t.expect.status.is.false
      done
    }
  }
}
