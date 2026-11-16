# Check the exact program expected by this command before reuse or removal.
# Recognize older shared-program keys and literal wrappers during reloads.
#
# $1: generated command name
# REPLY: unchanged
# return: 0|1
z.cls.instance.owns() {
  local z_cls_program=${functions[$1]-}
  local z_cls_suffix=${1#*.}
  local z_cls_expected=${z_cls_dispatch_programs[$z_cls_suffix]-}

  if z.is.null "$z_cls_expected"; then
    local z_cls_old_key="method:$z_cls_suffix"

    if z.str.includes "$z_cls_suffix" .; then
      z_cls_old_key="${z_cls_suffix##*.}:${z_cls_suffix%.*}"
    fi

    z_cls_expected=${z_cls_dispatch_programs[$z_cls_old_key]-}
  fi

  if z.is.not.null "$z_cls_program" && z.is.eq "$z_cls_program" "$z_cls_expected"; then
    return 0
  fi

  z.is.not.null "${z_cls_wrapper_bodies[$1]:-}" &&
    z.is.eq "$z_cls_program" "$z_cls_wrapper_bodies[$1]"
}
