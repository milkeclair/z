source ${z_main}

z.t.describe "z.pj.add._write"; {
  z.t.context "保存先がない場合"; {
    z.t.it "directoryを作って登録する"; {
      local XDG_CONFIG_HOME=/tmp/z_t/pj_write

      z.pj.add._write name=example dir=/tmp

      z.t.expect.status.is.true
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example"
      z.t.expect.reply /tmp
    }
  }

  z.t.context "登録がある場合"; {
    z.t.it "既存内容を維持して失敗する"; {
      local XDG_CONFIG_HOME=/tmp/z_t/pj_write_existing
      z.dir.make path="$XDG_CONFIG_HOME/z/pj"
      z.file.write path="$XDG_CONFIG_HOME/z/pj/example" content=before
      z.t.mock name=z.io.error

      z.pj.add._write name=example dir=/tmp

      z.t.expect.status.is.false
      z.file.read path="$XDG_CONFIG_HOME/z/pj/example"
      z.t.expect.reply before
    }
  }
}
