# remove docker resources for a compose project
#
# $1: compose project name
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy._docker.prune sample_project
z.wt_proxy._docker.prune() {
  local project_name=$1

  z.wt_proxy._docker.image.ids "$project_name"
  local -a image_ids=("${(@)REPLY}")
  z.wt_proxy._docker.volume.names "$project_name"
  local -a volume_names=("${(@)REPLY}")

  z.wt_proxy._docker.image.remove ${image_ids[@]} || return 1
  z.wt_proxy._docker.volume.remove ${volume_names[@]}
}
