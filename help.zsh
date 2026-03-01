# display help information
# if no argument is given, display the README
# if a function name is given, display the doc comment of the function
#
# $1?: function name
# REPLY: null
# return: null
#
# example:
#  z.help #=> display README
#  z.help z.arr.count #=> display doc comment of z.arr.count
z.help() {
  local function_name=$1

  if z.is.null $function_name; then
    z.help._show_readme
    return
  fi

  z.help._show_function_docs $function_name
}

# display help information for a specific modifier
#
# $1: modifier name
# $2?: function name
# REPLY: null
# return: null
#
# example:
#  z.help mod git #=> display README of git mod
#  z.help mod git z.git.commit #=> display doc comment of z.git.commit
z.help.mod() {
  local mod_name=$1
  local function_name=$2

  if z.is.null $mod_name; then
    z.io.error "Modifier name is required"
    return 1
  fi

  if z.is.null $function_name; then
    z.help.mod._show_readme $mod_name
    return
  fi

  z.help._show_function_docs "$function_name"
}

z.help._show_readme() {
  z.file.read path="${z_root}/README.md"
  printf '%s\n' "$REPLY"
}

z.help.mod._show_readme() {
  z.file.read path="${z_root}/mod/$1/README.md"
  printf '%s\n' "$REPLY"
}

z.help._show_function_docs() {
  local function_name=$1

  if z.int.is.zero $+functions[$function_name]; then
    z.io.error "Function not found: $function_name"
    return 1
  fi

  if ! z.help._find_docs $function_name; then
    z.io.error "Document not found: $function_name"
    return 1
  fi

  z.help._strip_comment_prefix "$REPLY"
  z.help._normalize_docs "$REPLY"
  printf '%s\n' "$REPLY"
}

z.help._find_docs() {
  local function_name=$1
  local files=(
    "${z_root}"/**/*.zsh(N)
  )

  for file_path in $files; do
    z.help._find_docs_in_file $function_name $file_path || continue
    return
  done

  return 1
}

z.help._strip_comment_prefix() {
  local docs=$1
  local stripped=()

  setopt local_options EXTENDED_GLOB

  # keep empty lines(@f)
  for line in "${(@f)docs}"; do
    z.help._trim_left_whitespace "$line"
    local trimmed_line=$REPLY

    if z.is.eq "$trimmed_line" "#"; then
      stripped+=("")
    elif z.str.start_with "$trimmed_line" "# "; then
      z.str.match.rest "$trimmed_line" "\\# "
      stripped+=("$REPLY")
    else
      stripped+=("$line")
    fi
  done

  REPLY=$(printf '%s\n' "${stripped[@]}")
}

z.help._normalize_docs() {
  local docs=$1
  local normalized=()

  for line in "${(@f)docs}"; do
    z.help._leading_whitespace "$line"
    local indentation=$REPLY
    # keep example comment indentation
    # e.g.
    #  example:
    #   z.arr.count my_array #<= this line has 1 space indentation
    line=${line//\\n/$'\n'$indentation}
    normalized+=("$line")
  done

  REPLY=$(printf '%s\n' "${normalized[@]}")
}

z.help._find_docs_in_file() {
  local function_name=$1
  local file_path=$2

  setopt local_options EXTENDED_GLOB

  z.file.read path=$file_path
  local lines=("${(@f)REPLY}")
  z.arr.count "${lines[@]}"
  local line_count=$REPLY
  local idx

  for ((idx=1; idx<=line_count; idx++)); do
    local line=${lines[$idx]}
    z.help._is_function_declaration_line $function_name "$line" || continue

    z.help._find_doc_start_line $idx "${lines[@]}"
    local start_line=$REPLY

    if ((start_line == idx)); then
      REPLY=""
      return 1
    fi

    local end_line=$((idx - 1))
    z.help._collect_docs_lines "$start_line" "$end_line" "${lines[@]}"
    return
  done

  return 1
}

z.help._is_function_declaration_line() {
  local function_name=$1
  local line=$2

  z.help._trim_left_whitespace "$line"
  local trimmed_line=$REPLY
  local declaration_prefix="${function_name}()"

  if ! z.str.start_with "$trimmed_line" "$declaration_prefix"; then
    return 1
  fi

  local declaration_suffix=${trimmed_line#"$declaration_prefix"}
  z.help._trim_left_whitespace "$declaration_suffix"
  z.is.eq "$REPLY" "{"
}

z.help._find_doc_start_line() {
  local declaration_line=$1
  shift
  local lines=("$@")
  local start_line=$declaration_line

  while ((start_line > 1)); do
    local prev_line=${lines[$((start_line - 1))]}

    if z.help._is_comment_line "$prev_line"; then
      ((start_line--))
      continue
    fi

    break
  done

  REPLY=$start_line
}

z.help._collect_docs_lines() {
  local start_line=$1
  local end_line=$2
  shift 2
  local lines=("$@")
  local docs_lines=()
  local docs_idx

  for ((docs_idx=start_line; docs_idx<=end_line; docs_idx++)); do
    docs_lines+=("${lines[$docs_idx]}")
  done

  z.arr.join.line "${docs_lines[@]}"
}

z.help._is_comment_line() {
  local line=$1

  z.help._trim_left_whitespace "$line"
  z.str.start_with "$REPLY" "#"
}

z.help._trim_left_whitespace() {
  local text=$1

  while z.is.not.null "$text"; do
    z.str.is.match "$text" "[[:space:]]*" || break
    z.str.match.rest "$text" "[[:space:]]"
    text=$REPLY
  done

  REPLY=$text
}

z.help._leading_whitespace() {
  local text=$1
  local whitespace=""

  while z.is.not.null "$text"; do
    if z.str.start_with "$text" " "; then
      whitespace+=" "
      z.str.match.rest "$text" " "
      text=$REPLY
      continue
    fi

    if z.str.start_with "$text" $'\t'; then
      whitespace+=$'\t'
      z.str.match.rest "$text" $'\t'
      text=$REPLY
      continue
    fi

    break
  done

  REPLY=$whitespace
}
