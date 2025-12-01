for not_file in ${z_root}/lib/dir/not/*.zsh; do
  source ${not_file}
done

# check if a directory exists
#
# $1: directory path
# REPLY: null
# return: 0|1
#
# example:
#  z.dir.exists "/path/to/dir" #=> return 0 if exists
z.dir.exists() {
  local dir=$1

  [[ -d $dir ]]
}
