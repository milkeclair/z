# Check the exact program expected by this command before reuse or removal.
# Recognize older shared-program keys and literal wrappers during reloads.
#
# $1: generated command name
# REPLY: unchanged
# return: 0|1
z.cls.instance.owns() {
  local __z_cls_program=${functions[$1]-}
  local __z_cls_suffix=${1#*.}
  local __z_cls_expected=${z_cls_dispatch_programs[$__z_cls_suffix]-}

  if z.is.null "$__z_cls_expected"; then
    local __z_cls_old_key="method:$__z_cls_suffix"

    if z.str.includes "$__z_cls_suffix" .; then
      __z_cls_old_key="${__z_cls_suffix##*.}:${__z_cls_suffix%.*}"
    fi
    __z_cls_expected=${z_cls_dispatch_programs[$__z_cls_old_key]-}
  fi

  { z.is.not.null "$__z_cls_program" && z.is.eq "$__z_cls_program" "$__z_cls_expected"; } ||
    { z.is.not.null "${z_cls_wrapper_bodies[$1]:-}" && z.is.eq "$__z_cls_program" "$z_cls_wrapper_bodies[$1]"; }
}
