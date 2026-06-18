source ${z_main}

z.t.describe "z.wtproxy._docker.image.remove"; {
  z.t.context "image IDを指定した場合"; {
    z.t.it "docker image rmを実行する"; {
      z.t.mock name="docker" behavior=":"

      z.wtproxy._docker.image.remove image_a image_b

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="docker"
      z.t.expect.reply.is.arr "image rm image_a" "image rm image_b"
    }
  }

  z.t.context "removeに失敗したimageがある場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="docker" behavior='
        z.is.eq "$3" image_b && return 1
        return 0
      '

      z.wtproxy._docker.image.remove image_a image_b

      z.t.expect.status.is.false
    }
  }
}
