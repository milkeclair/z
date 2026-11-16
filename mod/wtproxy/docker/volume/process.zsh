# 実際のボリューム名を指定してDockerボリュームを削除する
#
# $@: Dockerボリューム名
# REPLY: null
# return: すべて削除できた場合は0、それ以外は1
#
# example:
#  z.wtproxy._docker.volume.remove volume_name
z.wtproxy._docker.volume.remove() {
  local exit_status=0

  for volume_name in "$@"; do
    z.io.null docker volume rm "$volume_name" || exit_status=1
  done

  return $exit_status
}
