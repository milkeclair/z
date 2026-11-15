source ${z_main}

z.t.describe "z.pj.file.is.registration"; {
  z.t.context "通常ファイルの場合"; {
    z.t.it "trueを返す"; {
      z.file.make path=/tmp/z_t/pj_registration/plain with_dir=true

      z.pj.file.is.registration /tmp/z_t/pj_registration/plain

      z.t.expect.status.is.true
    }
  }

  z.t.context "directoryまたはsymlinkの場合"; {
    z.t.it "falseを返す"; {
      z.dir.make path=/tmp/z_t/pj_registration_other
      z.file.make path=/tmp/z_t/pj_registration_other/plain
      ln -s /tmp/z_t/pj_registration_other/plain /tmp/z_t/pj_registration_other/link

      z.pj.file.is.registration /tmp/z_t/pj_registration_other

      z.t.expect.status.is.false
      z.pj.file.is.registration /tmp/z_t/pj_registration_other/link

      z.t.expect.status.is.false
    }
  }
}
