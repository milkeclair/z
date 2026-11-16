# 実際のイメージIDを指定してDockerイメージを削除する
#
# $@: DockerイメージID
# REPLY: null
# return: すべて削除できた場合は0、それ以外は1
#
# example:
#  z.wtproxy._docker.image.remove image_id
z.wtproxy._docker.image.remove() {
  local exit_status=0

  for image_id in "$@"; do
    z.io.null docker image rm "$image_id" || exit_status=1
  done

  return $exit_status
}
