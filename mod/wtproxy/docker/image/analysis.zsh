# ComposeプロジェクトのDockerイメージIDを取得する
#
# $1: Composeのプロジェクト名
# REPLY: DockerイメージID
# return: null
#
# example:
#  # Dockerへ接続でき、対象のイメージがこの1件だけの場合
#  z.wtproxy._docker.image.ids sample_project
#  # REPLY: ("0123456789ab")
z.wtproxy._docker.image.ids() {
  local project_name=$1
  local label_filter="label=$z_wtproxy_docker_compose_project_label=$project_name"
  local output
  output=$(docker image ls --quiet --filter "$label_filter") || return 1

  z.str.split.line "$output"
  local -a image_ids=("${REPLY[@]}")
  z.arr.unique ${image_ids[@]}
}
