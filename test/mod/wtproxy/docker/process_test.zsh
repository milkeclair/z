source ${z_main}

z.t.describe "z.wtproxy._docker.prune"; {
  z.t.context "compose project名を指定した場合"; {
    z.t.it "imageとvolumeを削除する"; {
      z.t.mock name="z.wtproxy._docker.image.ids" behavior="z.return image_a image_b"
      z.t.mock name="z.wtproxy._docker.volume.names" behavior="z.return volume_a"
      z.t.mock name="z.wtproxy._docker.image.remove" behavior=":"
      z.t.mock name="z.wtproxy._docker.volume.remove" behavior=":"

      z.wtproxy._docker.prune project_feat

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="z.wtproxy._docker.image.remove"
      z.t.expect.reply.is.arr image_a image_b skip_unmock=true
      z.t.mock.result name="z.wtproxy._docker.volume.remove"
      z.t.expect.reply volume_a
    }
  }
}
