#!/usr/bin/env zsh
export Z_ROOT=${0:A:h:h:h:h}
source "$Z_ROOT/main.zsh"

# Report a failed scenario and stop its isolated shell.
# $@: failure description
# return: exits with status 1
scenario.fail() {
  print -ru2 -- "$*"
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
  arrays)
    source "$Z_ROOT/test/lib/cls/arrays.zsh"
    z.cls.new ArrayBox first
    first.fill
    first.items.get
    [[ ${#REPLY} == 3 && $REPLY[1] == "" && $REPLY[2] == "two words" && $REPLY[3] == last ]] || scenario.fail "array was flattened"
    first.items.set "" replaced
    first.items.get
    [[ ${#REPLY} == 2 && $REPLY[1] == "" && $REPLY[2] == replaced ]] || scenario.fail "array setter"
    first.items.set
    first.items.get
    (( ${#REPLY} == 0 )) || scenario.fail "empty array changed"
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
  scopes)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter counter
    outer_id=$counter
    counter.count.set 10
    inner() {
      local counter
      z.cls.new TestCounter counter || scenario.fail "same name in inner scope"
      [[ $counter != "$outer_id" ]] || scenario.fail "instance id reused"
      counter.increment
      counter.count.get
      [[ $REPLY == 1 ]] || scenario.fail "inner state"
      z.cls.delete counter || scenario.fail "inner cleanup"
    }
    inner
    [[ $counter == "$outer_id" ]] || scenario.fail "outer variable overwritten"
    counter.count.get
    [[ $REPLY == 10 ]] || scenario.fail "outer state overwritten"
    z.cls.delete counter
    (( ${+functions[counter.increment]} == 0 )) || scenario.fail "shared wrappers leaked"
    ;;
  different-class-scope)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    source "$Z_ROOT/test/lib/cls/arrays.zsh"
    z.cls.new TestCounter counter
    counter.count.set 8
    inner() {
      local counter
      z.cls.new ArrayBox counter || scenario.fail "different class in same name"
      counter.fill
      counter.items.get
      [[ ${#REPLY} == 3 ]] || scenario.fail "wrong class dispatched"
      counter.count.get 2>/dev/null && scenario.fail "method from outer instance was used"
      z.cls.delete counter
    }
    inner
    counter.count.get
    [[ $REPLY == 8 ]] || scenario.fail "outer class not restored"
    ;;
  pointers)
    setopt nounset
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter counter
    typeset -r other=$counter
    "$other.increment"
    counter.count.get
    [[ $REPLY == 1 ]] || scenario.fail "copied pointer did not share state"
    counter.add 4
    "$other.value"
    [[ $REPLY == 5 ]] || scenario.fail "pointer sees stale state"
    z.cls.delete other
    (( ${+functions[$counter.value]} == 0 )) || scenario.fail "pointer functions leaked"
    ;;
  errexit-cleanup)
    setopt errexit
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter counter
    counter.increment
    z.cls.delete counter
    (( ${#z_cls_instances} == 0 )) || scenario.fail "state leaked with errexit"
    ;;
  typed-state)
    typeset -i number=77
    typeset -F fraction=7.5
    typeset -a values=(outside)
    source "$Z_ROOT/test/lib/cls/typed-state.zsh"
    z.cls.new TypedState typed
    typed.fill
    typed.verify || scenario.fail "typed state was not preserved"
    typed.plain.get
    [[ $REPLY == $'quote\' slash\\ newline\n$(print SHOULD_NOT_RUN)' ]] || scenario.fail "scalar literal changed"
    typed.verify || scenario.fail "getter changed another attribute"
    [[ $number == 77 && $fraction == 7.5000000000 && $values[1] == outside ]] || scenario.fail "typed attribute leaked into caller scope"
    ;;
  arithmetic-setter)
    source "$Z_ROOT/test/lib/cls/arithmetic-setter.zsh"
    z.cls.new ArithmeticSetter arithmetic
    arithmetic.prepare
    arithmetic.count.set 'other+1'
    arithmetic.count.get
    [[ $REPLY == 14 ]] || scenario.fail "arithmetic setter lost the instance scope"
    ;;
  preserve-overrides)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    first.value() { REPLY=replacement; }
    first.increment
    first.count.get
    [[ $REPLY == 1 ]] || scenario.fail "redefining a copy changed shared code"
    z.cls.delete first
    first.value
    [[ $REPLY == replacement ]] || scenario.fail "user override was removed"
    ;;
  preserve-copied-overrides)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    functions -c first.increment first.value
    expected=$functions[first.value]
    z.cls.delete first
    [[ ${functions[first.value]-} == "$expected" ]] || scenario.fail "copied user override was removed"
    ;;
  exported-environment)
    setopt allexport
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter parent_instance
    zsh -f -c 'source "$Z_ROOT/main.zsh"
source "$Z_ROOT/test/lib/cls/counter.zsh"
z.cls.new TestCounter child_instance || exit 1
child_instance.increment
[[ $REPLY == 1 ]]' || scenario.fail "child shell inherited a false initialized marker"
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
  state)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    z.cls.new TestCounter second
    first.increment
    first.add 4
    [[ $REPLY == 5 ]] || scenario.fail "argument or result"
    second.count.get
    [[ $REPLY == 0 ]] || scenario.fail "instances share state"
    first.count.set 10
    first.increment
    first.value
    [[ $REPLY == 11 ]] || scenario.fail "setter and method state differ"
    first.label.set $'space "quote" \\ slash\n$(print SHOULD_NOT_RUN)'
    first.label.get
    [[ $REPLY == $'space "quote" \\ slash\n$(print SHOULD_NOT_RUN)' ]] || scenario.fail "setter changed literal data"
    first.label.set ""
    first.label.get
    [[ $REPLY == "" ]] || scenario.fail "empty value"
    ;;
  nested)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    first.twice first
    first.value
    [[ $REPLY == 2 ]] || scenario.fail "same-instance nested calls lose state"
    ;;
  result)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    first.fail reason
    result=$?
    [[ $result == 7 && $REPLY == failure:reason ]] || scenario.fail "return contract"
    first.value
    [[ $REPLY == 1 ]] || scenario.fail "state not saved on return"
    ;;
  function-trap)
    typeset -i trap_calls=0
    TRAPDEBUG() { (( ++trap_calls )); return 0; }
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
  lifecycle)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    z.cls.new TestCounter first 2>/dev/null && scenario.fail "reference was reassigned"
    z.cls.new Missing missing 2>/dev/null && scenario.fail "missing class"
    z.cls.delete first || scenario.fail delete
    (( ${+functions[first.increment]} == 0 && ${+functions[first.count.get]} == 0 && ${+functions[first.count.set]} == 0 )) || scenario.fail "functions leaked"
    recreate() {
      local first
      z.cls.new TestCounter first || scenario.fail recreate
      first.value
      [[ $REPLY == 0 ]] || scenario.fail "deleted state leaked"
      z.cls.delete first
    }
    recreate
    ;;
  reassignment)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    local_reference() {
      local counter
      z.cls.new TestCounter counter
      [[ $parameters[counter] == *local*readonly* ]] || scenario.fail "caller binding is not readonly"
      (counter=other) 2>/dev/null && scenario.fail "direct reassignment succeeded"
      z.cls.new TestCounter counter 2>/dev/null && scenario.fail "constructor reassigned the reference"
      local copy=$counter
      z.cls.new TestCounter copy 2>/dev/null && scenario.fail "constructor replaced a copied reference"
      counter.count.set 3
      counter.increment
      [[ $REPLY == 4 ]] || scenario.fail "readonly reference froze attributes"
      z.cls.delete counter
    }
    local_reference
    ;;
  collision)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    first.value() { REPLY=original; }
    z.cls.new TestCounter first 2>/dev/null && scenario.fail "function overwritten"
    first.value
    [[ $REPLY == original ]] || scenario.fail "existing function changed"
    (( ${+functions[first.increment]} == 0 )) || scenario.fail "partial instance leaked"
    ;;
esac
unsetopt nounset
exit 0
