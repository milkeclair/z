# Validate command names before an instance changes the shell.
#
# $@: proposed command names
# REPLY: unchanged
# return: 0 if every name is available or owned, otherwise 1 with an error
z.cls.instance.commands.validate() {
  local REPLY=""
  local __z_cls_member

  for __z_cls_member in "$@"; do
    if z.var.exists "aliases[$__z_cls_member]" || z.var.exists "galiases[$__z_cls_member]"; then
      z.io.error "Command $__z_cls_member already exists."
      return 1
    fi
    if z.is.not.null "${z_cls_wrapper_refs[$__z_cls_member]:-}" &&
        z.cls.instance.owns "$__z_cls_member"; then
      continue
    fi
    if z.var.exists "functions[$__z_cls_member]" || z.var.exists "commands[$__z_cls_member]"; then
      z.io.error "Command $__z_cls_member already exists."
      return 1
    fi
  done

  return 0
}

# Install shared dispatch programs and count their instance references.
#
# $@: validated command names
# REPLY: unchanged
# return: 0
z.cls.instance.commands.install() {
  local __z_cls_member

  for __z_cls_member in "$@"; do
    local __z_cls_name=${__z_cls_member#*.}
    local __z_cls_operation=method

    if z.str.includes "$__z_cls_name" .; then
      __z_cls_operation=${__z_cls_name##*.}
      __z_cls_name=${__z_cls_name%.*}
    fi

    local __z_cls_template="z_cls_dispatch_${__z_cls_operation}_$__z_cls_name"
    if ! z.var.exists "functions[$__z_cls_template]"; then
      functions[$__z_cls_template]='z.cls.instance.call "${funcstack[1]%%.*}" '"$__z_cls_operation ${(q)__z_cls_name}"' "$@"'
      z_cls_dispatch_programs[${__z_cls_member#*.}]=$functions[$__z_cls_template]
    fi

    functions -c "$__z_cls_template" "$__z_cls_member"
    unset "z_cls_wrapper_bodies[$__z_cls_member]"
    (( z_cls_wrapper_refs[$__z_cls_member] += 1 ))
  done

  return 0
}
