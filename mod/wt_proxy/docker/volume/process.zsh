# remove docker volumes by actual volume names
#
# $@: docker volume names
# REPLY: null
# return: 0 if all removals succeed, otherwise 1
#
# example:
#  z.wt_proxy._docker.volume.remove volume_name
z.wt_proxy._docker.volume.remove() {
  local exit_status=0

  for volume_name in "$@"; do
    docker volume rm "$volume_name" >/dev/null 2>&1 || exit_status=1
  done

  return $exit_status
}
