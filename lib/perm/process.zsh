# change permissions and ownership for a path
#
# $path: target path
# $owner?: owner name or id
# $group?: group name or id
# $mode?: chmod mode
# $mode_owner?: owner permissions separated by comma
# $mode_group?: group permissions separated by comma
# $mode_other?: other permissions separated by comma
# REPLY: null
# return: 0 if changed or no changes are requested, otherwise 1
#
# example:
#  z.perm path=/path/to/file mode=600
#  z.perm path=/path/to/file \
#    mode_owner=read,write,execute \
#    mode_group=none,none,none \
#    mode_other=none,none,none
z.perm() {
  z.perm._apply recursive=false "$@" # zls: ignore
}

# change permissions and ownership recursively for a directory
#
# $path: target directory path
# $owner?: owner name or id
# $group?: group name or id
# $mode?: chmod mode
# $mode_owner?: owner permissions separated by comma
# $mode_group?: group permissions separated by comma
# $mode_other?: other permissions separated by comma
# REPLY: null
# return: 0 if changed or no changes are requested, otherwise 1
#
# example:
#  z.perm.dir path=/path/to/dir mode=755
z.perm.dir() {
  z.perm._apply recursive=true "$@" # zls: ignore
}

# change permissions and ownership with optional recursive flag
#
# $recursive?: apply changes recursively(default: false)
# $path: target path
# $owner?: owner name or id
# $group?: group name or id
# $mode?: chmod mode
# $mode_owner?: owner permissions separated by comma
# $mode_group?: group permissions separated by comma
# $mode_other?: other permissions separated by comma
# REPLY: null
# return: 0 if changed or no changes are requested, otherwise 1
#
# example:
#  z.perm._apply recursive=false path=/path/to/file mode=600
z.perm._apply() {
  z.arg.named recursive $@ default=false && local recursive=$REPLY
  z.arg.named path $@ && local target_path=$REPLY

  if z.is.null "$target_path"; then
    z.io.error "path is required"
    return 1
  fi

  local recursive_opts=()
  z.is.true $recursive && recursive_opts=(-R)

  z.perm._owner_spec "$@"
  local owner_status=$?
  local owner_spec=$REPLY
  if z.int.is.zero $owner_status; then
    chown ${recursive_opts[@]} "$owner_spec" "$target_path" || return 1
  fi

  z.perm._mode "$@"
  local mode_status=$?
  local mode=$REPLY
  if z.int.is.zero $mode_status; then
    chmod ${recursive_opts[@]} "$mode" "$target_path" || return 1
  fi
}

# build chown owner spec
#
# $owner?: owner name or id
# $group?: group name or id
# REPLY: owner spec for chown
# return: 0 if owner or group is present, otherwise 1
#
# example:
#  z.perm._owner_spec owner=user group=group #=> "user:group"
z.perm._owner_spec() {
  z.arg.named owner $@ default="" && local owner=$REPLY
  z.arg.named group $@ default="" && local group=$REPLY

  if z.is.null "$owner" && z.is.null "$group"; then
    z.return
    return 1
  fi

  if z.is.not.null "$owner" && z.is.not.null "$group"; then
    z.return "$owner:$group"
  elif z.is.not.null "$owner"; then
    z.return "$owner"
  else
    z.return ":$group"
  fi
}

# build chmod mode
#
# $mode?: chmod mode
# $mode_owner?: owner permissions separated by comma
# $mode_group?: group permissions separated by comma
# $mode_other?: other permissions separated by comma
# REPLY: chmod mode
# return: 0 if mode can be built, otherwise 1
#
# example:
#  z.perm._mode \
#    mode_owner=read,write,none \
#    mode_group=read,none,none \
#    mode_other=none,none,none
z.perm._mode() {
  z.arg.named mode $@ default="" && local mode=$REPLY
  if z.is.not.null "$mode"; then
    z.return "$mode"
    return 0
  fi

  local has_mode_parts=false
  for arg in "$@"; do
    z.str.start_with "$arg" "mode_owner=" && has_mode_parts=true
    z.str.start_with "$arg" "mode_group=" && has_mode_parts=true
    z.str.start_with "$arg" "mode_other=" && has_mode_parts=true
  done

  if z.is.false $has_mode_parts; then
    z.return
    return 1
  fi

  z.arg.named mode_owner $@ default="none,none,none" && local mode_owner=$REPLY
  z.arg.named mode_group $@ default="none,none,none" && local mode_group=$REPLY
  z.arg.named mode_other $@ default="none,none,none" && local mode_other=$REPLY

  z.perm._mode_digit "$mode_owner" || return 1
  local owner_digit=$REPLY
  z.perm._mode_digit "$mode_group" || return 1
  local group_digit=$REPLY
  z.perm._mode_digit "$mode_other" || return 1
  local other_digit=$REPLY

  z.return "${owner_digit}${group_digit}${other_digit}"
}

# convert permission names to chmod digit
#
# $1: comma-separated permissions
# REPLY: chmod digit
# return: 0 if permissions are valid, otherwise 1
#
# example:
#  z.perm._mode_digit read,write,none #=> 6
z.perm._mode_digit() {
  local mode_values=$1
  local digit=0

  z.str.split str="$mode_values" delimiter=","
  local permissions=($REPLY)

  for permission in $permissions; do
    case $permission in
    read)
      ((digit += 4))
      ;;
    write)
      ((digit += 2))
      ;;
    execute)
      ((digit += 1))
      ;;
    none|"")
      ;;
    *)
      z.io.error "invalid permission: $permission"
      return 1
      ;;
    esac
  done

  z.return $digit
}
