# remove docker images by actual image IDs
#
# $@: docker image IDs
# REPLY: null
# return: 0 if all removals succeed, otherwise 1
#
# example:
#  z.wt_proxy._docker.image.remove image_id
z.wt_proxy._docker.image.remove() {
  local exit_status=0

  for image_id in "$@"; do
    docker image rm "$image_id" >/dev/null 2>&1 || exit_status=1
  done

  return $exit_status
}
