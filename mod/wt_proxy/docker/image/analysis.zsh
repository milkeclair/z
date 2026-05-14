# get docker image IDs for a compose project
#
# $1: compose project name
# REPLY: docker image IDs
# return: null
#
# example:
#  z.wt_proxy._docker.image.ids sample_project
z.wt_proxy._docker.image.ids() {
  local project_name=$1
  local label_filter="label=$z_wt_proxy_docker_compose_project_label=$project_name"
  local output=$(docker image ls --quiet --filter "$label_filter")

  local -a image_ids=("${(@f)output}")
  z.arr.unique ${image_ids[@]}
}
