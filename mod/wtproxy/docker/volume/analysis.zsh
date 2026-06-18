# get docker volume names for a compose project
#
# $1: compose project name
# REPLY: docker volume names
# return: null
#
# example:
#  z.wtproxy._docker.volume.names sample_project
z.wtproxy._docker.volume.names() {
  local project_name=$1
  local label_filter="label=$z_wtproxy_docker_compose_project_label=$project_name"
  local output
  output=$(docker volume ls --quiet --filter "$label_filter") || return 1

  local -a volume_names=("${(@f)output}")
  z.arr.unique ${volume_names[@]}
}
