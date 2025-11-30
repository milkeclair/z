# register a function
# avoids namespace pollution
#
# $1: function name
# $2: function body
# REPLY: null
# return: null
#
# example:
#  z.fn my_func 'z.io "Hello, World!"'
z.fn() {
  z.fn._ensure_store

  local name=$1
  local body="$2"
  local hash=$(uuidgen)
  z.str.gsub str="$hash" search="-" replace=""
  local key="z_fn_${REPLY}"

  if z.fn.exists $name; then
    z.io.error "Function $name already exists."
    return 1
  fi

  functions[$key]="$body"
  z_fn_set[$name]=$key
  z_fn_source[$name]=$PWD
}

# call a registered function
#
# $1: function name
# $@?: function arguments
# REPLY: function return value
# return: function return status
#
# example:
#  z.fn.call my_func arg1 arg2
z.fn.call() {
  z.fn._ensure_store

  local name=$1
  shift

  if z.fn.not_exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  ${z_fn_set[$name]} "$@"
}

# delete a registered function
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.fn.delete my_func
z.fn.delete() {
  z.fn._ensure_store

  local name=$1

  if z.fn.not_exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  local key=${z_fn_set[$name]}

  unfunction $key
  unset "z_fn_set[$name]"
  unset "z_fn_source[$name]"
}

# delete all registered functions
#
# REPLY: null
# return: null
#
# example:
#  z.fn.delete_all
z.fn.delete_all() {
  z.fn._ensure_store

  for value in ${(v)z_fn_set}; do
    unfunction $value
  done

  z_fn_set=()
  z_fn_source=()
}

# edit a registered function
#
# $1: function name
# $2: new function body
# REPLY: null
# return: null
#
# example:
#  z.fn.edit my_func 'z.io "New Body"'
z.fn.edit() {
  z.fn._ensure_store

  local name=$1
  local new_body="$2"
  local hash=$(uuidgen)
  z.str.gsub str=$hash search="-" replace=""
  local key="z_fn_${REPLY}"

  if z.fn.not_exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  local old_key=${z_fn_set[$name]}
  unfunction $old_key
  functions[$key]="$new_body"
  z_fn_set[$name]=$key
  z_fn_source[$name]=$PWD
}

# ensure that the function store is initialized
#
# REPLY: null
# return: null
#
# example:
#  z.fn._ensure_store
z.fn._ensure_store() {
  z.var.exists z_fn_set || typeset -gA z_fn_set
  z.var.exists z_fn_source || typeset -gA z_fn_source
}
