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
  [path]="analysis:process"
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
  path
  status
  str
  t
)

local -A loaded_files=()

for module in $z_module_depends_order; do
  local parts=(${(s/:/)z_modules[$module]})

  for part in $parts; do
    local base_file="${z_root}/lib/${module}/${part}.zsh"
    if [[ -f $base_file && ${loaded_files[$base_file]} != true ]]; then
      source "$base_file" "$@"
      loaded_files[$base_file]=true
    fi

    local part_dir="${z_root}/lib/${module}/${part}"
    local part_nested_files=("${part_dir}"/**/*.zsh(N))
    for part_nested_file in $part_nested_files; do
      if [[ -f $part_nested_file && ${loaded_files[$part_nested_file]} != true ]]; then
        source "$part_nested_file" "$@"
        loaded_files[$part_nested_file]=true
      fi
    done
  done

  local module_files=("${z_root}/lib/${module}"/**/*.zsh(N))
  for module_file in $module_files; do
    if [[ -f $module_file && ${loaded_files[$module_file]} != true ]]; then
      source "$module_file" "$@"
      loaded_files[$module_file]=true
    fi
  done
done

if [[ -d "${z_root}/mod" ]]; then
  local mod_dirs=("${z_root}/mod"/*(/))
  for mod_dir in $mod_dirs; do
    local mod_files=("${mod_dir}"/**/*.zsh(N))
    for mod_file in $mod_files; do
      if [[ -f $mod_file && ${loaded_files[$mod_file]} != true ]]; then
        source "$mod_file" "$@"
        loaded_files[$mod_file]=true
      fi
    done
  done
fi

source "${z_root}/install.zsh"
source "${z_root}/install/mod.zsh"
source "${z_root}/uninstall.zsh"

z.arg() {}
z.arr() {}
z.dir() {}
z.file() {}
z.hash() {}
z.int() {}
z.str() {}
z.path() {}
