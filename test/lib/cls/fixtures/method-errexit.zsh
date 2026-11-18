# 新しいZshでメソッドの失敗が終了まで伝わることを確認する。
unset z_mode
source "$Z_ROOT/main.zsh"

z.cls.draw StopEarly
  z.cls.attr count default=0

  z.cls.fn run
    false
    REPLY=continued
    print -r -- SHOULD_NOT_RUN
  z.cls.fn.done
z.cls.drew

local object=""
z.cls.new StopEarly object
setopt errexit
$object.run
print -r -- SHOULD_NOT_RUN
