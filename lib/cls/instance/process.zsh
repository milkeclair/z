# Restore one instance's attributes, execute an operation, and persist changes.
# Same-instance nested calls reuse the active local scope.
#
# $1: instance variable name or reference
# $2: method, get, or set
# $3: method or attribute name
# $@?: operation arguments
# REPLY: operation result
# return: operation exit status
z.cls.instance.call() {
  local __z_cls_instance=${(P)1:-}
  local __z_cls_operation=$2
  local __z_cls_member=$3

  z.is.not.null "${z_cls_instances[$1]:-}" && __z_cls_instance=$1

  if z.is.null "${z_cls_instances[$__z_cls_instance]:-}"; then
    z.io.error "Instance reference $1 is not available in this scope."
    return 1
  fi

  local __z_cls_key="${z_cls_instances[$__z_cls_instance]}:$__z_cls_member"

  if z.is.eq "$__z_cls_operation" method; then
    z.var.exists "z_cls_bodies[$__z_cls_key]" || return 1
  else
    z.var.exists "z_cls_defaults[$__z_cls_key]" || return 1
  fi
  shift 3

  if z.is.not.null "${z_cls_active[$__z_cls_instance]:-}"; then
    if z.is.not.eq "${__z_cls_current_instance:-}" "$__z_cls_instance"; then
      z.io.error "Instance $__z_cls_instance is active in another instance call."
      return 1
    fi
    z.cls.instance.execute "$__z_cls_instance" "$__z_cls_operation" "$__z_cls_member" "$@"
    return $?
  fi

  if z.is.not.eq "$__z_cls_operation" method; then
    local __z_cls_declaration=$z_cls_values[$__z_cls_instance:$__z_cls_member]
    local __z_cls_scalar_prefix="typeset -- $__z_cls_member="
    local __z_cls_integer_prefix="typeset -i $__z_cls_member="
    if z.str.start_with "$__z_cls_declaration" "$__z_cls_scalar_prefix" ||
        z.str.start_with "$__z_cls_declaration" "$__z_cls_integer_prefix"; then
      if z.is.eq "$__z_cls_operation" get; then
        z.int.is.zero $# || return 1
        local __z_cls_literal=${__z_cls_declaration#*=}
        REPLY=${(Q)__z_cls_literal}
        return 0
      fi
      z.int.is.eq $# 1 || return 1
      if z.str.start_with "$__z_cls_declaration" "$__z_cls_scalar_prefix"; then
        z_cls_values[$__z_cls_instance:$__z_cls_member]="$__z_cls_scalar_prefix${(qq)1}"
        return 0
      fi
      if [[ $1 == <-> || $1 == -<-> ]]; then
        local -i __z_cls_numeric=$1
        z_cls_values[$__z_cls_instance:$__z_cls_member]="$__z_cls_integer_prefix${(qq)__z_cls_numeric}"
        return 0
      fi
    fi
  fi

  local __z_cls_current_instance=$__z_cls_instance
  local __z_cls_class=${z_cls_instances[$__z_cls_instance]}
  local __z_cls_result=0
  local __z_cls_attribute
  local -a __z_cls_attributes=("$__z_cls_member")

  if z.is.not.eq "$__z_cls_operation" get; then
    __z_cls_attributes=(${=z_cls_class_attrs[$__z_cls_class]})
  fi

  for __z_cls_attribute in "${__z_cls_attributes[@]}"; do
    eval "$z_cls_values[$__z_cls_instance:$__z_cls_attribute]"
  done
  z_cls_active[$__z_cls_instance]=1
  {
    if z.cls.instance.execute "$__z_cls_instance" "$__z_cls_operation" "$__z_cls_member" "$@"; then
      __z_cls_result=0
    else
      __z_cls_result=$?
    fi
  } always {
    if z.is.not.eq "$__z_cls_operation" get; then
      for __z_cls_attribute in "${__z_cls_attributes[@]}"; do
        if ! z.cls.instance.snapshot "$__z_cls_instance" "$__z_cls_attribute"; then
          z_cls_values[$__z_cls_instance:$__z_cls_attribute]="$(typeset -p "$__z_cls_attribute")"
        fi
      done
    fi
    unset "z_cls_active[$__z_cls_instance]"
  }

  return $__z_cls_result
}

# Run a method in a child function scope, or access a restored attribute.
#
# $1: instance name
# $2: method, get, or set
# $3: method or attribute name
# $@?: operation arguments
# REPLY: operation result
# return: operation exit status
z.cls.instance.execute() {
  local __z_cls_target=$1
  local __z_cls_kind=$2
  local __z_cls_name=$3

  shift 3
  case $__z_cls_kind in
    method)
      local __z_cls_body=$z_cls_bodies[${z_cls_instances[$__z_cls_target]}:$__z_cls_name]
      () { eval "$__z_cls_body"; } "$@"
      ;;
    get)
      z.int.is.zero $# || return 1
      if [[ ${(tP)__z_cls_name} == *array* || ${(tP)__z_cls_name} == *association* ]]; then
        REPLY=("${(@P)__z_cls_name}")
      else
        REPLY=${(P)__z_cls_name}
      fi
      ;;
    set)
      if [[ ${(tP)__z_cls_name} == *array* || ${(tP)__z_cls_name} == *association* ]]; then
        set -A "$__z_cls_name" "$@"
      else
        z.int.is.eq $# 1 || return 1
        : ${(P)__z_cls_name::=$1}
      fi
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
z.cls.instance.snapshot() {
  local __z_cls_snapshot_key="$1:$2"
  local __z_cls_snapshot_name=$2

  if ! z.var.exists "$__z_cls_snapshot_name"; then
    z_cls_values[$__z_cls_snapshot_key]="typeset -- $__z_cls_snapshot_name; unset $__z_cls_snapshot_name"
    return 0
  fi

  local __z_cls_snapshot_type=${(tP)__z_cls_snapshot_name}

  case $__z_cls_snapshot_type in
    scalar|scalar-local)
      local __z_cls_snapshot_value=${(P)__z_cls_snapshot_name}
      z_cls_values[$__z_cls_snapshot_key]="typeset -- $__z_cls_snapshot_name=${(qq)__z_cls_snapshot_value}"
      ;;
    integer|integer-local)
      local __z_cls_snapshot_value=${(P)__z_cls_snapshot_name}
      if [[ $__z_cls_snapshot_value == <-> || $__z_cls_snapshot_value == -<-> ]]; then
        z_cls_values[$__z_cls_snapshot_key]="typeset -i $__z_cls_snapshot_name=${(qq)__z_cls_snapshot_value}"
      else
        return 1
      fi
      ;;
    array|array-local)
      local -a __z_cls_snapshot_values=("${(@P)__z_cls_snapshot_name}")
      z_cls_values[$__z_cls_snapshot_key]="typeset -a $__z_cls_snapshot_name=( ${(j: :)${(@qq)__z_cls_snapshot_values}} )"
      ;;
    association|association-local)
      local -a __z_cls_snapshot_values=("${(@Pkv)__z_cls_snapshot_name}")
      z_cls_values[$__z_cls_snapshot_key]="typeset -A $__z_cls_snapshot_name=( ${(j: :)${(@qq)__z_cls_snapshot_values}} )"
      ;;
    *)
      return 1
      ;;
  esac
}
