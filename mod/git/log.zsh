z.git.log() {
  z.git.user._show

  echo ""
  echo "--- commits ---"
  z.git.log._pretty
}

z.git.log._pretty() {
  command git log --graph --date=format:'%y/%m/%d %R' --pretty=format:' %C(yellow)%h%Creset [%C(green)%cd%Creset] %C(cyan)%cn%Creset%C(auto)%d%Creset%n %s%n%w(120,1,1)%b'
}
