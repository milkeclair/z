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
  local z_cls_instance=${(P)1:-}
  local z_cls_operation=$2
  local z_cls_member=$3

  z.is.not.null "${z_cls_instances[$1]:-}" && z_cls_instance=$1

  if z.is.null "${z_cls_instances[$z_cls_instance]:-}"; then
    z.io.error "Instance reference $1 is not available in this scope."
    return 1
  fi

  local z_cls_key="${z_cls_instances[$z_cls_instance]}:$z_cls_member"

  if z.is.eq "$z_cls_operation" method; then
    z.var.exists "z_cls_bodies[$z_cls_key]" || return 1
  else
    z.var.exists "z_cls_defaults[$z_cls_key]" || return 1
  fi

  shift 3

  if z.is.not.null "${z_cls_active[$z_cls_instance]:-}"; then
    if z.is.not.eq "${z_cls_current_instance:-}" "$z_cls_instance"; then
      z.io.error "Instance $z_cls_instance is active in another instance call."
      return 1
    fi

    z.cls.instance.execute "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
    return $?
  fi

  if z.is.not.eq "$z_cls_operation" method; then
    local z_cls_declaration=$z_cls_values[$z_cls_instance:$z_cls_member]
    local z_cls_scalar_prefix="typeset -- $z_cls_member="
    local z_cls_integer_prefix="typeset -i $z_cls_member="

    if z.str.start_with "$z_cls_declaration" "$z_cls_scalar_prefix" ||
        z.str.start_with "$z_cls_declaration" "$z_cls_integer_prefix"; then
      if z.is.eq "$z_cls_operation" get; then
        z.int.is.zero $# || return 1

        local z_cls_literal=${z_cls_declaration#*=}

        REPLY=${(Q)z_cls_literal}
        return 0
      fi

      z.int.is.eq $# 1 || return 1

      if z.str.start_with "$z_cls_declaration" "$z_cls_scalar_prefix"; then
        z_cls_values[$z_cls_instance:$z_cls_member]="$z_cls_scalar_prefix${(qq)1}"
        return 0
      fi

      if [[ $1 == <-> || $1 == -<-> ]]; then
        local -i z_cls_numeric=$1

        z_cls_values[$z_cls_instance:$z_cls_member]="$z_cls_integer_prefix${(qq)z_cls_numeric}"
        return 0
      fi
    fi
  fi

  local z_cls_class=${z_cls_instances[$z_cls_instance]}
  local -a z_cls_attributes=("$z_cls_member")

  if z.is.not.eq "$z_cls_operation" get; then
    z_cls_attributes=(${=z_cls_class_attrs[$z_cls_class]})
  fi

  local z_cls_attribute

  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$z_cls_instance:$z_cls_attribute]"
  done

  local z_cls_current_instance=$z_cls_instance
  local z_cls_result=0

  z_cls_active[$z_cls_instance]=1
  {
    if z.cls.instance.execute "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"; then
      z_cls_result=0
    else
      z_cls_result=$?
    fi
  } always {
    if z.is.not.eq "$z_cls_operation" get; then
      for z_cls_attribute in "${z_cls_attributes[@]}"; do
        if ! z.cls.instance.snapshot "$z_cls_instance" "$z_cls_attribute"; then
          z_cls_values[$z_cls_instance:$z_cls_attribute]="$(typeset -p "$z_cls_attribute")"
        fi
      done
    fi

    unset "z_cls_active[$z_cls_instance]"
  }

  return $z_cls_result
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
      z.int.is.zero $# || return 1

      if [[ ${(tP)z_cls_name} == *array* || ${(tP)z_cls_name} == *association* ]]; then
        REPLY=("${(@P)z_cls_name}")
      else
        REPLY=${(P)z_cls_name}
      fi
      ;;
    set)
      if [[ ${(tP)z_cls_name} == *array* || ${(tP)z_cls_name} == *association* ]]; then
        set -A "$z_cls_name" "$@"
      else
        z.int.is.eq $# 1 || return 1

        : ${(P)z_cls_name::=$1}
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

      if [[ $z_cls_snapshot_value == <-> || $z_cls_snapshot_value == -<-> ]]; then
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
