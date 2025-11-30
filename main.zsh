export z_root=${Z_ROOT:-${${(%):-%N}:A:h}}

local -A z_modules=(
  [arg]="analysis:operator:process"
  [arr]="analysis:operator:process"
  [common]="dsl:operator:wrap"
  [debug]="process"
  [dir]="operator:process"
  [file]="operator:process"
  [fn]="analysis:operator:process"
  [hash]="analysis:operator:process"
  [int]="operator"
  [io]="process"
  [mode]="process"
  [status]="analysis:operator"
  [str]="operator:process"
  [t]="state:dsl:expect:log:mock:process"
  [var]="operator:analysis"
)

local z_module_depends_order=(
  arg
  arr
  common
  debug
  dir
  file
  var # var are used in fn
  fn
  hash
  int
  io
  mode
  status
  str
  t
)

for module in $z_module_depends_order; do
  local parts=(${(s/:/)z_modules[$module]})

  for part in $parts; do
    source "${z_root}/lib/${module}/${part}.zsh"
  done
done

source "${z_root}/install.zsh"
source "${z_root}/uninstall.zsh"

z.arg() {}
z.arr() {}
z.dir() {}
z.file() {}
z.hash() {}
z.int() {}
z.str() {}
z.arg() {}
