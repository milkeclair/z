z.version() {
  z.io "v0.1.0"
}

z.version.latest() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest version" && return 1

  # { "tag_name": "v1.2.3" } => {"tag_name":"v1.2.3"}
  z.str.gsub str="$response" search="[[:space:]]" replace="" pattern=true
  # {"tag_name":"v1.2.3"} => v1.2.3"}
  z.str.is.match "$REPLY" '*"tag_name":"*"*' || return 1
  z.str.gsub str="$REPLY" search='*"tag_name":"' replace="" pattern=true
  # v1.2.3"} => v1.2.3
  z.str.gsub str="$REPLY" search='"*' replace="" pattern=true
  local tag_name=$REPLY
  z.is.null $tag_name && return 1

  z.io $tag_name
}

z.version.latest.note() {
  local api_url="https://api.github.com/repos/milkeclair/z/releases/latest"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch latest release note" && return 1

  z.str.is.match "$response" '*"body"*' || return 1
  # { "tag_name": "v1.2.3", "body": "release note" } => : "release note" }
  z.str.gsub str="$response" search='*"body"' replace="" pattern=true
  # : "release note" } => :"release note" }
  z.str.gsub str="$REPLY" search=':[[:space:]]*"' replace=':"' pattern=true
  # :"release note" } => release note" }
  z.str.match.rest "$REPLY" ':"'
  # release note" } => release note
  z.str.gsub str="$REPLY" search='"*' replace="" pattern=true
  z.is.null $REPLY && return 1

  z.str.gsub str="$REPLY" search='\"' replace='"'

  z.io "$REPLY"
}

z.version.note() {
  local current_version=$(z.version)
  local api_url="https://api.github.com/repos/milkeclair/z/releases/tags/${current_version}"
  local response
  response=$(command curl -fsSL $api_url)
  z.status.is.false && z.io.error "failed to fetch release note" && return 1

  z.str.is.match "$response" '*"body"*' || return 1
  # { "tag_name": "v1.2.3", "body": "release note" } => : "release note" }
  z.str.gsub str="$response" search='*"body"' replace="" pattern=true
  # : "release note" } => :"release note" }
  z.str.gsub str="$REPLY" search=':[[:space:]]*"' replace=':"' pattern=true
  # :"release note" } => release note" }
  z.str.match.rest "$REPLY" ':"'
  # release note" } => release note
  z.str.gsub str="$REPLY" search='"*' replace="" pattern=true
  z.is.null $REPLY && return 1

  z.str.gsub str="$REPLY" search='\"' replace='"'

  z.io "$REPLY"
}
