typeset -g z_wt_proxy_host=127.0.0.1
typeset -g z_wt_proxy_state_dir_name=worktree-proxy
typeset -g z_wt_proxy_config_dir_name=worktree-proxy
typeset -g z_wt_proxy_config_file_extension=env
typeset -g z_wt_proxy_port_range=1000
typeset -g z_wt_proxy_default_slug=missing_slug
typeset -g z_wt_proxy_public_port_env_prefix=Z_WT_PROXY_PUBLIC_PORT_
typeset -g z_wt_proxy_public_port_config_prefix=public_port_
typeset -g z_wt_proxy_port_key_prefix=port_
typeset -g z_wt_proxy_host_port_env_prefix=Z_WT_PROXY_HOST_PORT_
typeset -g z_wt_proxy_docker_compose_project_label=com.docker.compose.project

typeset -gA z_wt_proxy_default_config_values=(
  public_port_1 3000
  public_port_2 5432
  public_port_3 5173
)

typeset -ga z_wt_proxy_localhost_hosts=(
  localhost
  ip6-localhost
  ::1
  0:0:0:0:0:0:0:1
)
