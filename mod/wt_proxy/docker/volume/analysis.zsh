# get docker volume names for a compose project
#
# $1: compose project name
# REPLY: docker volume names
# return: null
#
# example:
#  z.wt_proxy._docker.volume.names sample_project
z.wt_proxy._docker.volume.names() {
  local project_name=$1
  local label_filter="label=$z_wt_proxy_docker_compose_project_label=$project_name"
  local output=$(docker volume ls --quiet --filter "$label_filter")

  local -a volume_names=("${(@f)output}")
  z.arr.unique ${volume_names[@]}
}
