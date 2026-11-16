# Restore one instance's attributes, execute an operation, and persist changes.
# Same-instance nested calls reuse the active local scope.
#
# $1: instance variable name or reference
# $2: method, get, or set
# $3: method or attribute name
# $@?: operation arguments
# REPLY: operation result
# return: operation exit status
z.cls.instance._call() {
  local z_cls_instance=${(P)1:-}
  local z_cls_operation=$2
  local z_cls_member=$3

  z.is.not.null "${z_cls_instances[$1]:-}" && z_cls_instance=$1
  z.cls.instance.call._validate "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$1" || return 1
  shift 3

  if z.is.not.null "${z_cls_active[$z_cls_instance]:-}"; then
    z.cls.instance._execute "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
  elif z.is.eq "$z_cls_operation" method; then
    z.cls.instance.call._run "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
  else
    z.cls.instance.call._access "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
  fi
}

# Run a method in a child function scope, or access a restored attribute.
#
# $1: instance name
# $2: method, get, or set
# $3: method or attribute name
# $@?: operation arguments
# REPLY: operation result
# return: operation exit status
z.cls.instance._execute() {
  local z_cls_target=$1
  local z_cls_kind=$2
  local z_cls_name=$3

  shift 3

  case $z_cls_kind in
    method)
      local z_cls_body=$z_cls_bodies[${z_cls_instances[$z_cls_target]}:$z_cls_name]

      () {
        eval "$z_cls_body"
      } "$@"
      ;;
    get)
      z.cls.instance.execute._get "$z_cls_name" "$@"
      ;;
    set)
      z.cls.instance.execute._set "$z_cls_name" "$@"
      ;;
  esac
}

# Save one restored attribute without spawning a subshell for ordinary values.
# Return 1 for uncommon flags so the caller snapshots in the attribute scope.
#
# $1: instance reference
# $2: attribute name
# REPLY: unchanged
# return: 0 when saved, 1 when canonical typeset output is needed
z.cls.instance._snapshot() {
  local z_cls_snapshot_key="$1:$2"
  local z_cls_snapshot_name=$2

  if ! z.var.exists "$z_cls_snapshot_name"; then
    z_cls_values[$z_cls_snapshot_key]="typeset -- $z_cls_snapshot_name; unset $z_cls_snapshot_name"
    return 0
  fi

  local z_cls_snapshot_type=${(tP)z_cls_snapshot_name}

  case $z_cls_snapshot_type in
    scalar|scalar-local)
      local z_cls_snapshot_value=${(P)z_cls_snapshot_name}

      z_cls_values[$z_cls_snapshot_key]="typeset -- $z_cls_snapshot_name=${(qq)z_cls_snapshot_value}"
      ;;
    integer|integer-local)
      local z_cls_snapshot_value=${(P)z_cls_snapshot_name}

      if z.int.is.match "$z_cls_snapshot_value"; then
        z_cls_values[$z_cls_snapshot_key]="typeset -i $z_cls_snapshot_name=${(qq)z_cls_snapshot_value}"
      else
        return 1
      fi
      ;;
    array|array-local)
      local -a z_cls_snapshot_values=("${(@P)z_cls_snapshot_name}")

      z_cls_values[$z_cls_snapshot_key]="typeset -a $z_cls_snapshot_name=( ${(j: :)${(@qq)z_cls_snapshot_values}} )"
      ;;
    association|association-local)
      local -a z_cls_snapshot_values=("${(@Pkv)z_cls_snapshot_name}")

      z_cls_values[$z_cls_snapshot_key]="typeset -A $z_cls_snapshot_name=( ${(j: :)${(@qq)z_cls_snapshot_values}} )"
      ;;
    *)
      return 1
      ;;
  esac
}

# Release a validated instance's commands and stored attributes.
#
# $1: existing inactive instance reference
# REPLY: unchanged
# return: 0
z.cls.instance._release() {
  local z_cls_id=$1
  local z_cls_member

  for z_cls_member in ${=z_cls_members[$z_cls_id]}; do
    z_cls_wrapper_refs[$z_cls_member]=$(( z_cls_wrapper_refs[$z_cls_member] - 1 ))

    if z.int.is.zero $z_cls_wrapper_refs[$z_cls_member]; then
      if z.cls.instance._owns "$z_cls_member"; then
        unfunction "$z_cls_member"
      fi

      unset "z_cls_wrapper_refs[$z_cls_member]" "z_cls_wrapper_bodies[$z_cls_member]"
    fi
  done

  for z_cls_member in ${=z_cls_class_attrs[${z_cls_instances[$z_cls_id]}]}; do
    unset "z_cls_values[$z_cls_id:$z_cls_member]"
  done

  # 未設定のactive要素も管理ノードを残すため、一緒に削除する。
  unset "z_cls_instances[$z_cls_id]" "z_cls_members[$z_cls_id]" "z_cls_active[$z_cls_id]"
}
