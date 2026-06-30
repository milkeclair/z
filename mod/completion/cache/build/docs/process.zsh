# build function docs cache from a file
#
# $1: source file path
# REPLY: null
# return: null
#
# example:
#  z.completion.cache.build.docs._from_file /path/to/source.zsh
z.completion.cache.build.docs._from_file() {
  setopt local_options EXTENDED_GLOB

  local file_path=$1
  z.file.read path=$file_path
  local lines=("${(@f)REPLY}")
  local line_count=${#lines[@]}
  local idx=0
  local docs_lines=()

  for ((idx=1; idx<=line_count; idx++)); do
    local line=${lines[$idx]}
    if z.completion.cache.build.line.is._comment "$line"; then
      docs_lines+=("$line")
      continue
    fi

    if z.completion.cache.build.line._function_name "$line"; then
      local function_name=$REPLY
      if z.int.is.positive ${+functions[$function_name]} &&
        z.int.is.positive ${#docs_lines[@]}; then
        z.arr.join.line "${docs_lines[@]}"
        z.help._strip_comment_prefix "$REPLY"
        z.help._normalize_docs "$REPLY"
        z_completion_docs[$function_name]=$REPLY
      fi
    fi

    docs_lines=()
  done
}
