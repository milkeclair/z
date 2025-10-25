typeset -gA z_t_states

local state_dir="${z_root}/lib/t/state"
for state_file in "${state_dir}"/*.zsh; do
  source "${state_file}" $1
done

# state management module
z.t._state() {
}
