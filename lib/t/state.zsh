typeset -gA z_t_states

for state_file in ${z_root}/lib/t/state/*.zsh; do
  source ${state_file} $1
done

# state management module
z.t._state() {
}
