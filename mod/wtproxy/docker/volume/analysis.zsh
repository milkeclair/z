# ComposeプロジェクトのDockerボリューム名を取得する
#
# $1: Composeのプロジェクト名
# REPLY: Dockerボリューム名
# return: null
#
# example:
#  # Dockerへ接続でき、対象のボリュームがこの1件だけの場合
#  z.wtproxy._docker.volume.names sample_project
#  # REPLY: ("sample_project_data")
z.wtproxy._docker.volume.names() {
  local project_name=$1
  local label_filter="label=$z_wtproxy_docker_compose_project_label=$project_name"
  local output
  output=$(docker volume ls --quiet --filter "$label_filter") || return 1

  local -a volume_names=("${(@f)output}")
  z.arr.unique ${volume_names[@]}
}
