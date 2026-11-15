source ${z_main}

z.t.describe "pj mod"; {
  z.t.it "modとして登録される"; {
    z.mod.is.registered pj
    z.t.expect.status.is.true
  }
}
