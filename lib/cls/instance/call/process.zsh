# Validate a resolved operation before dispatch or attribute restoration.
#
# $1: resolved instance reference
# $2: method, get, or set
# $3: member name
# $4: original binding or reference for error reporting
# REPLY: unchanged
# return: 0|1
z.cls.instance.call.validate() {
  local z_cls_instance=$1

  if z.is.null "${z_cls_instances[$z_cls_instance]:-}"; then
    z.io.error "Instance reference $4 is not available in this scope."
    return 1
  fi

  local z_cls_key="${z_cls_instances[$z_cls_instance]}:$3"

  if z.is.eq "$2" method; then
    z.var.exists "z_cls_bodies[$z_cls_key]" || return 1
  else
    z.var.exists "z_cls_defaults[$z_cls_key]" || return 1
  fi

  if z.is.not.null "${z_cls_active[$z_cls_instance]:-}" &&
      z.is.not.eq "${z_cls_current_instance:-}" "$z_cls_instance"; then
    z.io.error "Instance $z_cls_instance is active in another instance call."
    return 1
  fi

  return 0
}

# Access an ordinary saved scalar, restoring attribute scope for other cases.
#
# $1: inactive instance reference
# $2: get or set
# $3: attribute name
# $@?: accessor arguments
# REPLY: accessor result
# return: accessor exit status
z.cls.instance.call.access() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local z_cls_member=$3
  local z_cls_declaration=$z_cls_values[$1:$3]
  local z_cls_scalar_prefix="typeset -- $3="
  local z_cls_integer_prefix="typeset -i $3="

  shift 3

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

  z.cls.instance.call.run "$z_cls_instance" "$z_cls_operation" "$z_cls_member" "$@"
}

# Own restored attributes through execution, persistence, and active-state cleanup.
#
# $1: inactive instance reference
# $2: method, get, or set
# $3: member name
# $@?: operation arguments
# REPLY: operation result
# return: operation exit status
z.cls.instance.call.run() {
  local z_cls_instance=$1
  local z_cls_operation=$2
  local -a z_cls_attributes=("$3")

  if z.is.not.eq "$z_cls_operation" get; then
    z_cls_attributes=(${=z_cls_class_attrs[${z_cls_instances[$z_cls_instance]}]})
  fi

  local z_cls_attribute

  for z_cls_attribute in "${z_cls_attributes[@]}"; do
    eval "$z_cls_values[$z_cls_instance:$z_cls_attribute]"
  done

  local z_cls_current_instance=$z_cls_instance
  local z_cls_result=0

  z_cls_active[$z_cls_instance]=1
  {
    if z.cls.instance.execute "$@"; then
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
