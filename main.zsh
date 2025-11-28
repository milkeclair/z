export z_root=${Z_ROOT:-${${(%):-%N}:A:h}}

local -A z_modules=(
  [arg]="analysis:operator:process"
  [arr]="analysis:operator:process"
  [common]="dsl:operator:wrap"
  [debug]="process"
  [dir]="operator:process"
  [file]="operator:process"
  [fn]="analysis:operator:process"
  [int]="operator"
  [io]="process"
  [mode]="process"
  [status]="analysis:operator"
  [str]="operator:process"
  [t]="state:dsl:expect:log:mock:process"
)

for module in ${(k)z_modules}; do
  local -a parts=(${(s/:/)z_modules[$module]})

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
z.int() {}
z.str() {}
