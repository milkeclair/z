# 実際のイメージIDを指定してDockerイメージを削除する
#
# $@: DockerイメージID
# REPLY: null
# return: すべて削除できた場合は0、それ以外は1
#
# example:
#  # 指定したイメージが存在し、削除できる場合
#  z.wtproxy._docker.image.remove 0123456789ab
#  # return: 0
#  # 結果: イメージ0123456789abが削除される
z.wtproxy._docker.image.remove() {
  local exit_status=0

  for image_id in "$@"; do
    z.io.null docker image rm "$image_id" || exit_status=1
  done

  return $exit_status
}
