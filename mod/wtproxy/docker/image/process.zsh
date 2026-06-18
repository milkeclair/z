# remove docker images by actual image IDs
#
# $@: docker image IDs
# REPLY: null
# return: 0 if all removals succeed, otherwise 1
#
# example:
#  z.wtproxy._docker.image.remove image_id
z.wtproxy._docker.image.remove() {
  local exit_status=0

  for image_id in "$@"; do
    z.io.null docker image rm "$image_id" || exit_status=1
  done

  return $exit_status
}
