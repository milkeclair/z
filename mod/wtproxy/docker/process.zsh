# remove docker resources for a compose project
#
# $1: compose project name
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._docker.prune sample_project
z.wtproxy._docker.prune() {
  local project_name=$1

  z.wtproxy._docker.image.ids "$project_name"
  local -a image_ids=("${(@)REPLY}")
  z.wtproxy._docker.volume.names "$project_name"
  local -a volume_names=("${(@)REPLY}")

  z.wtproxy._docker.image.remove ${image_ids[@]} || return 1
  z.wtproxy._docker.volume.remove ${volume_names[@]}
}
