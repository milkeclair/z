source ${z_main}

z.t.describe "z.path.current"; {
  z.t.it "現在の作業ディレクトリのパスを返す"; {
    z.path.current

    z.t.expect.reply "$(pwd)"
  }
}

z.t.describe "z.path.home"; {
  z.t.it "ホームディレクトリのパスを返す"; {
    z.path.home

    z.t.expect.reply "$HOME"
  }
}
