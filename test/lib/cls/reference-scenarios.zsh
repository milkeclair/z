#!/usr/bin/env zsh
export Z_ROOT=${0:A:h:h:h:h}
source "$Z_ROOT/main.zsh"

# シナリオの失敗を報告し、隔離したシェルを終了する。
# $@: 失敗の説明
# return: 1でシェルを終了する
scenario.fail() {
  z.io.error "$*"
  exit 1
}

(( ${+functions[z.cls.draw]} )) || scenario.fail "class API is missing"

case $1 in
  scopes)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter counter
    outer_id=$counter
    counter.count.set 10
    inner() {
      local counter=""
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
      local counter=""
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
  preserve-overrides)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    first.value() {
      REPLY=replacement
    }
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
  cleanup-recreate)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    local -a saved_refs=()
    local index
    local reference
    # 同名localの参照をスコープ外に保持し、一部だけを先に削除する。
    for (( index=1; index<=72; index++ )); do
      () {
        local object=""
        z.cls.new TestCounter object || scenario.fail create
        saved_refs+=("$object")
      }
    done
    for reference in "${(@)saved_refs[1,36]}"; do
      z.cls.delete "$reference" || scenario.fail "partial cleanup"
    done
    reference=$saved_refs[37]
    "$reference.count.set" 42
    "$reference.value"
    [[ $REPLY == 42 ]] || scenario.fail "live state lost during cleanup"
    object.increment() {
      REPLY=custom
    }
    for reference in "${(@)saved_refs[37,72]}"; do
      z.cls.delete "$reference" || scenario.fail "final cleanup"
    done
    object.increment
    [[ $REPLY == custom ]] || scenario.fail "user replacement removed"
    (( ${+functions[$reference.value]} == 0 )) || scenario.fail "deleted reference callable"
    () {
      local fresh=""
      z.cls.new TestCounter fresh || scenario.fail "class definition lost"
      fresh.increment
      [[ $REPLY == 1 ]] || scenario.fail "cached program lost or old state reused"
      z.cls.delete fresh || scenario.fail "recreated instance cleanup"
    }
    ;;
  lifecycle)
    source "$Z_ROOT/test/lib/cls/counter.zsh"
    z.cls.new TestCounter first
    z.cls.new TestCounter first 2>/dev/null && scenario.fail "reference was reassigned"
    z.cls.new Missing missing 2>/dev/null && scenario.fail "missing class"
    z.cls.delete first || scenario.fail delete
    (( ${+functions[first.increment]} == 0 && ${+functions[first.count.get]} == 0 && ${+functions[first.count.set]} == 0 )) || scenario.fail "functions leaked"
    recreate() {
      local first=""
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
      local counter=""
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
    first.value() {
      REPLY=original
    }
    z.cls.new TestCounter first 2>/dev/null && scenario.fail "function overwritten"
    first.value
    [[ $REPLY == original ]] || scenario.fail "existing function changed"
    (( ${+functions[first.increment]} == 0 )) || scenario.fail "partial instance leaked"
    ;;
esac
unsetopt nounset
exit 0
