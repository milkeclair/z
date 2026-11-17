# allexport下の親から環境を継承し、exec後のZshで初めてクラスを初期化する。
source "$Z_ROOT/main.zsh"
source "$Z_ROOT/test/lib/cls/counter.zsh"
z.cls.new TestCounter child_instance || exit 1
child_instance.increment
print -r -- "$REPLY"
