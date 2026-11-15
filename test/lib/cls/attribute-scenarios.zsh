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

esac
unsetopt nounset
exit 0
