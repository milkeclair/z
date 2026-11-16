# z.ではルートの名前空間を取得し、深い接頭辞では公開関数の候補を取得する
#
# $1: 関数名の接頭辞
# REPLY: 一致する名前空間名または関数名|null
# return: 0|1
#
# example:
#  z.completion.function._candidates z.arg.
z.completion.function._candidates() {
  local prefix=$1
  local function_names=("${z_completion_function_names[@]}")

  local candidates=()
  local namespace_pattern='^z\.[^.]*\.'
  for function_name in $function_names; do
    if z.str.start_with "$function_name" "z." &&
      ! z.completion.function.is._private "$function_name" &&
      z.str.start_with "$function_name" "$prefix"; then
      local candidate=$function_name
      if z.is.eq "$prefix" z.; then
        z.str.match "$function_name" "$namespace_pattern"
        candidate=$REPLY
        z.is.null "$candidate" && continue
      fi
      candidates+=("$candidate")
    fi
  done

  if z.int.is.zero ${#candidates[@]}; then
    return 1
  fi

  if z.is.eq "$prefix" z.; then
    z.arr.unique "${candidates[@]}"
    candidates=("${(@)REPLY}")
  fi

  z.arr.join.line "${candidates[@]}"
}
