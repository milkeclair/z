# allexport下の親から環境を継承し、通常のZshで初めてクラスを初期化する。
unset z_mode
source "$Z_ROOT/main.zsh"
source "$Z_ROOT/test/lib/cls/fixtures/counter.zsh"
z.cls.new TestCounter child_instance || exit 1
child_instance.increment
print -r -- "$REPLY"
