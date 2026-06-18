source ${z_main}

z.t.describe "z.wtproxy._docker.volume.remove"; {
  z.t.context "volume名を指定した場合"; {
    z.t.it "docker volume rmを実行する"; {
      z.t.mock name="docker" behavior=":"

      z.wtproxy._docker.volume.remove volume_a volume_b

      z.t.expect.status.is.true skip_unmock=true
      z.t.mock.result name="docker"
      z.t.expect.reply.is.arr "volume rm volume_a" "volume rm volume_b"
    }
  }

  z.t.context "removeに失敗したvolumeがある場合"; {
    z.t.it "falseを返す"; {
      z.t.mock name="docker" behavior='
        z.is.eq "$3" volume_b && return 1
        return 0
      '

      z.wtproxy._docker.volume.remove volume_a volume_b

      z.t.expect.status.is.false
    }
  }
}
