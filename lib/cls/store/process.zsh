# Initialize class definitions, instance state, and capture bookkeeping.
#
# REPLY: unchanged
# return: 0
z.cls.store.ensure() {
  [[ ${z_cls_store_ready:-0} == 1 && ${+z_cls_dispatch_programs} == 1 ]] && return 0
  zmodload zsh/parameter
  z.var.exists z_cls_classes || typeset -gA z_cls_classes
  z.var.exists z_cls_class_attrs || typeset -gA z_cls_class_attrs
  z.var.exists z_cls_class_methods || typeset -gA z_cls_class_methods
  z.var.exists z_cls_defaults || typeset -gA z_cls_defaults
  z.var.exists z_cls_bodies || typeset -gA z_cls_bodies
  z.var.exists z_cls_instances || typeset -gA z_cls_instances
  z.var.exists z_cls_values || typeset -gA z_cls_values
  z.var.exists z_cls_members || typeset -gA z_cls_members
  z.var.exists z_cls_wrapper_refs || typeset -gA z_cls_wrapper_refs
  z.var.exists z_cls_wrapper_bodies || typeset -gA z_cls_wrapper_bodies
  z.var.exists z_cls_dispatch_programs || typeset -gA z_cls_dispatch_programs
  z.var.exists z_cls_next_id || typeset -gi z_cls_next_id=0
  z.var.exists z_cls_active || typeset -gA z_cls_active
  z.var.exists z_cls_drawing || typeset -g z_cls_drawing=''
  z.var.exists z_cls_capture_method || typeset -g z_cls_capture_method=''
  typeset -gi +x z_cls_store_ready=1
}
