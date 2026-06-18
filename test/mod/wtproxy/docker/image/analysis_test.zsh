source ${z_main}

z.t.describe "z.wtproxy._docker.image.ids"; {
  z.t.context "compose projectに紐づくimageがある場合"; {
    z.t.it "重複を除いたimage IDを返す"; {
      z.t.mock name="docker" behavior='
        z.io image_a
        z.io image_a
        z.io image_b
      '

      z.wtproxy._docker.image.ids project_feat

      z.t.expect.reply.is.arr image_a image_b
    }
  }
}
