# Begin a class definition in the current shell.
#
# $1: class name
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.draw Counter; { z.cls.attr count 0; z.cls.drew; }
z.cls.draw() {
  z.cls.store.ensure

  if ! z.int.is.eq $# 1 || ! z.cls.is.name "$1"; then
    z.io.error "Expected a valid class name."
    return 1
  fi

  if z.is.not.null "$z_cls_drawing" || z.is.not.null "${z_cls_classes[$1]:-}"; then
    z.io.error "Class $1 already exists or a definition is active."
    return 1
  fi

  z_cls_class_attrs[$1]=''
  z_cls_class_methods[$1]=''
  z_cls_drawing=$1
}

# Register a scalar attribute and its default value in the active class.
#
# $1: attribute name
# $2: default value, including an empty string
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.attr count 0
z.cls.attr() {
  z.cls.store.ensure

  if ! z.int.is.eq $# 2 || z.is.null "$z_cls_drawing" || ! z.cls.is.attribute "$1"; then
    z.io.error "Expected an active class, an ordinary attribute name, and a default."
    return 1
  fi

  local key="$z_cls_drawing:$1"

  if z.var.exists "z_cls_defaults[$key]"; then
    z.io.error "Attribute $1 already exists."
    return 1
  fi

  z_cls_defaults[$key]=$2
  z_cls_class_attrs[$z_cls_drawing]+="$1 "
}

# Begin a method block, or register an explicitly supplied body.
# Place z.cls.fn.done on its own statement after an unquoted method body.
#
# $1: method name
# $2?: inline body
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.fn increment
#    (( ++count ))
#  z.cls.fn.done
z.cls.fn() {
  z.cls.store.ensure

  local invalid=0
  local key="$z_cls_drawing:${1:-}"

  if z.int.is.lt $# 1 || z.int.is.gt $# 2 || z.is.null "$z_cls_drawing" || ! z.cls.is.name "${1:-}"; then
    z.io.error "Expected an active class and a valid method name."
    invalid=1
  elif z.var.exists "z_cls_bodies[$key]"; then
    z.io.error "Method $1 already exists."
    invalid=1
  fi

  if z.int.is.gteq $# 2; then
    z.int.is.zero $invalid || return 1
    z_cls_bodies[$key]=$2
    z_cls_class_methods[$z_cls_drawing]+="$1 "
    return 0
  fi

  unsetopt localoptions
  z.cls.capture.start "${1:-invalid}" "${(j:|:)funcstack[2,-1]}" "${funcfiletrace[1]%:*}" "$invalid"
}

# Publish the active class after all methods have been collected.
#
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.drew
z.cls.drew() {
  z.cls.store.ensure

  if z.is.null "$z_cls_drawing"; then
    z.io.error "No class definition is active."
    return 1
  fi

  z_cls_classes[$z_cls_drawing]=1
  z_cls_drawing=''
}

# Discard an unfinished definition and restore its DEBUG interception.
#
# REPLY: unchanged
# return: 0
#
# example:
#  z.cls.abort
z.cls.abort() {
  z.cls.store.ensure
  z.cls.capture.stop

  # 共通getterのループ変数を呼出元のreadonly参照から隔離する。
  local arg=""
  local REPLY=""
  local key

  z.hash.keys z_cls_defaults
  for key in "${(@)REPLY}"; do
    z.str.start_with "$key" "$z_cls_drawing:" && unset "z_cls_defaults[$key]"
  done

  z.hash.keys z_cls_bodies
  for key in "${(@)REPLY}"; do
    z.str.start_with "$key" "$z_cls_drawing:" && unset "z_cls_bodies[$key]"
  done

  if z.is.not.null "$z_cls_drawing"; then
    unset "z_cls_class_attrs[$z_cls_drawing]" "z_cls_class_methods[$z_cls_drawing]"
  fi

  z_cls_drawing=''

  return 0
}

# Create an independent instance with a readonly reference binding.
#
# $1: published class name
# $2: variable receiving the instance reference; declare it local in the caller when needed
# REPLY: opaque instance reference
# return: 0|1
#
# example:
#  z.cls.new Counter counter
z.cls.new() {
  z.cls.store.ensure

  if ! z.int.is.eq $# 2 || z.is.null "${z_cls_classes[$1]:-}" || ! z.cls.is.attribute "$2"; then
    z.io.error "Expected an existing class and an ordinary instance variable name."
    return 1
  fi

  local __z_cls_class=$1
  local __z_cls_binding=$2

  if [[ ${parameters[$__z_cls_binding]:-} == *readonly* ||
        ${parameters[$__z_cls_binding]:-} == *array* ||
        ${parameters[$__z_cls_binding]:-} == *association* ||
        ${parameters[$__z_cls_binding]:-} == *integer* ||
        ${parameters[$__z_cls_binding]:-} == *float* ]]; then
    z.io.error "Instance variable $__z_cls_binding must be a writable scalar."
    return 1
  fi

  if z.is.not.null "${z_cls_instances[${(P)__z_cls_binding:-}]:-}"; then
    z.io.error "Instance variable $__z_cls_binding already holds a reference."
    return 1
  fi

  (( ++z_cls_next_id ))

  local __z_cls_id="z_cls_${$}_$z_cls_next_id"

  z.cls.instance.commands "$__z_cls_class" "$__z_cls_binding" "$__z_cls_id"

  local -a __z_cls_wrappers=("${(@)REPLY}")

  z.cls.instance.commands.validate "${__z_cls_wrappers[@]}" || return 1

  local __z_cls_member

  for __z_cls_member in ${=z_cls_class_attrs[$__z_cls_class]}; do
    z_cls_values[$__z_cls_id:$__z_cls_member]="typeset -- $__z_cls_member=${(qq)z_cls_defaults[$__z_cls_class:$__z_cls_member]}"
  done

  z.cls.instance.commands.install "${__z_cls_wrappers[@]}"

  z_cls_members[$__z_cls_id]="${(j: :)__z_cls_wrappers}"
  z_cls_instances[$__z_cls_id]=$__z_cls_class
  : ${(P)__z_cls_binding::=$__z_cls_id}
  typeset -gr -- "$__z_cls_binding"

  REPLY=$__z_cls_id
}

# Remove an instance, its generated commands, and its saved attributes.
#
# $1: instance variable name or reference
# REPLY: unchanged
# return: 0|1
#
# example:
#  z.cls.delete counter
z.cls.delete() {
  z.cls.store.ensure

  local REPLY=""

  z.int.is.eq $# 1 || return 1

  local __z_cls_id=${(P)1:-}
  local __z_cls_member

  z.is.not.null "${z_cls_instances[$1]:-}" && __z_cls_id=$1

  if z.is.null "${z_cls_instances[$__z_cls_id]:-}" || z.is.not.null "${z_cls_active[$__z_cls_id]:-}"; then
    z.io.error "Expected an existing, inactive instance reference."
    return 1
  fi

  for __z_cls_member in ${=z_cls_members[$__z_cls_id]}; do
    z_cls_wrapper_refs[$__z_cls_member]=$(( z_cls_wrapper_refs[$__z_cls_member] - 1 ))
    if z.int.is.zero $z_cls_wrapper_refs[$__z_cls_member]; then
      if z.cls.instance.owns "$__z_cls_member"; then
        unfunction "$__z_cls_member"
      fi
      unset "z_cls_wrapper_refs[$__z_cls_member]" "z_cls_wrapper_bodies[$__z_cls_member]"
    fi
  done

  for __z_cls_member in ${=z_cls_class_attrs[${z_cls_instances[$__z_cls_id]}]}; do
    unset "z_cls_values[$__z_cls_id:$__z_cls_member]"
  done

  # 未設定の要素参照でも管理ノードが残るため、activeも明示的に削除する。
  unset "z_cls_instances[$__z_cls_id]" "z_cls_members[$__z_cls_id]" "z_cls_active[$__z_cls_id]"

  # IDの解決後に隔離し、argという参照名の動的な参照先を保つ。
  local arg=""
  z.hash.count z_cls_instances
  if z.int.is.zero $REPLY; then
    # 全実体の削除後に空テーブルを作り直し、バケットと未設定ノードを解放する。
    z_cls_instances=()
    z_cls_values=()
    z_cls_members=()
    z_cls_active=()
    z_cls_wrapper_refs=()
    z_cls_wrapper_bodies=()
  fi

  return 0
}
