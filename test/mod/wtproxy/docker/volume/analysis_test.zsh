source ${z_main}

z.t.describe "z.wtproxy._docker.volume.names"; {
  z.t.context "compose projectに紐づくvolumeがある場合"; {
    z.t.it "重複を除いたvolume名を返す"; {
      z.t.mock name="docker" behavior='
        z.io volume_a
        z.io volume_a
        z.io volume_b
      '

      z.wtproxy._docker.volume.names project_feat

      z.t.expect.reply.is.arr volume_a volume_b
    }
  }

  z.t.context "docker volume lsに失敗した場合"; {
    z.t.it "失敗を返す"; {
      z.t.mock name="docker" behavior="return 1"

      z.wtproxy._docker.volume.names project_feat

      z.t.expect.status.is.false
    }
  }
}
