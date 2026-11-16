# ComposeプロジェクトのDockerリソースを削除する
#
# $1: Composeのプロジェクト名
# REPLY: null
# return: null
#
# example:
#  # sample_projectの未使用イメージ・ボリュームを削除できる場合
#  z.wtproxy._docker.prune sample_project
#  # 結果: そのComposeプロジェクトのイメージとボリュームが削除される
z.wtproxy._docker.prune() {
  local project_name=$1

  z.wtproxy._docker.image.ids "$project_name" || return 1
  local -a image_ids=("${(@)REPLY}")
  z.wtproxy._docker.volume.names "$project_name" || return 1
  local -a volume_names=("${(@)REPLY}")

  z.wtproxy._docker.image.remove ${image_ids[@]} || return 1
  z.wtproxy._docker.volume.remove ${volume_names[@]}
}
