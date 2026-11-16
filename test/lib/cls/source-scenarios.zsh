#!/usr/bin/env zsh
export Z_ROOT=${0:A:h:h:h:h}
source "$Z_ROOT/main.zsh"

# Report a failed scenario and stop its isolated shell.
# $@: failure description
# return: exits with status 1
scenario.fail() {
  z.io.error "$*"
  exit 1
}

(( ${+functions[z.cls.draw]} )) || scenario.fail "class API is missing"

case $1 in
  options)
    setopt "${(@s:,:)2}"
    before_options="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]"
    source "$Z_ROOT/test/lib/cls/counter.zsh" || scenario.fail definition
    after_options="$options[localoptions]:$options[localtraps]:$options[debugbeforecmd]"
    [[ $after_options == "$before_options" ]] || scenario.fail "shell options changed: $before_options -> $after_options"
    z.cls.new TestCounter first
    first.increment
    [[ $REPLY == 1 ]] || scenario.fail "capture failed under option $2"
    ;;
  missing-end)
    source "$Z_ROOT/test/lib/cls/unfinished.zsh"
    [[ -z $z_cls_capture_method && -z $z_cls_drawing ]] || scenario.fail "capture leaked beyond source"
    (( ${+functions[TRAPDEBUG]} == 0 )) || scenario.fail "DEBUG trap leaked"
    z.cls.new Unfinished first 2>/dev/null && scenario.fail "unfinished class published"
    ;;
  invalid-header)
    typeset -gi side_effect=0
    source "$Z_ROOT/test/lib/cls/invalid-header.zsh"
    (( side_effect == 0 )) || scenario.fail "invalid method body executed"
    [[ -z $z_cls_drawing && -z $z_cls_capture_method ]] || scenario.fail "invalid method leaked state"
    ;;
  body-syntax)
    source "$Z_ROOT/test/lib/cls/body-syntax.zsh"
    z.cls.new SyntaxBox first
    first.run test
    result=$?
    [[ $result == 9 && $REPLY == "value:test" ]] || scenario.fail "syntax or status not preserved"
    ;;
  capture)
    typeset -i count=40
    source "$Z_ROOT/test/lib/cls/counter.zsh" || scenario.fail definition
    [[ $count == 40 ]] || scenario.fail "body executed during source"
    z.cls.new TestCounter first || scenario.fail new
    first.loop
    [[ $REPLY == default:one:two ]] || scenario.fail loop
    [[ $count == 40 ]] || scenario.fail "caller variable changed"
    ;;
  function-trap)
    typeset -i trap_calls=0
    TRAPDEBUG() {
      (( ++trap_calls ))
      return 0
    }
    before=$functions[TRAPDEBUG]
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    [[ $functions[TRAPDEBUG] == "$before" ]] || scenario.fail "function DEBUG trap changed"
    (( trap_calls > 0 )) || scenario.fail "original DEBUG trap never ran"
    z.cls.new TestCounter first
    first.increment
    [[ $REPLY == 1 ]] || scenario.fail "capture failed with DEBUG trap"
    ;;
  noisy-list-trap)
    trap 'print -r -- "TRACE:$ZSH_DEBUG_CMD"' DEBUG
    before=$(trap)
    source "$Z_ROOT/test/lib/cls/counter.zsh" || scenario.fail definition
    after=$(trap)
    [[ $after == "$before" ]] || scenario.fail "printing DEBUG trap changed"
    ;;
  list-trap)
    typeset -i trap_calls=0
    trap '(( ++trap_calls ))' DEBUG
    before=$(trap)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    after=$(trap)
    [[ $after == "$before" ]] || scenario.fail "list DEBUG trap changed"
    z.cls.new TestCounter first
    first.increment
    [[ $REPLY == 1 ]] || scenario.fail "capture failed with list trap"
    ;;

esac
unsetopt nounset
exit 0
