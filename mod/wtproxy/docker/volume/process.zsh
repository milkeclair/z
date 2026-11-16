# 実際のボリューム名を指定してDockerボリュームを削除する
#
# $@: Dockerボリューム名
# REPLY: null
# return: すべて削除できた場合は0、それ以外は1
#
# example:
#  # 指定したボリュームが存在し、使用されていない場合
#  z.wtproxy._docker.volume.remove sample_project_data
#  # return: 0
#  # 結果: ボリュームsample_project_dataが削除される
z.wtproxy._docker.volume.remove() {
  local exit_status=0

  for volume_name in "$@"; do
    z.io.null docker volume rm "$volume_name" || exit_status=1
  done

  return $exit_status
}
