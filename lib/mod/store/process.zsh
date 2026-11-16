# z modの保存領域が初期化されていることを保証する
#
# REPLY: null
# return: null
#
# example:
#  # modの保存領域が未宣言の場合
#  z.mod._store.ensure
#  # 状態: z_mod_names=()、z_mod_depends=()、z_mod_current=""
z.mod._store.ensure() {
  z.var.exists z_mod_names || typeset -gA z_mod_names
  z.var.exists z_mod_depends || typeset -gA z_mod_depends
  z.var.exists z_mod_current || typeset -g z_mod_current=""
}
