# Classes

Class definitions are ordinary Zsh files. Load z first, then source the
definition file. Method bodies stay unquoted shell code.

Save this as `counter.zsh`:

```zsh
z.cls.draw Counter; {
  z.cls.attr count 0

  z.cls.fn increment
    (( ++count ))
    REPLY=$count
  z.cls.fn.done

  z.cls.fn add
    (( count += $1 ))
    REPLY=$count
  z.cls.fn.done

  z.cls.drew
}
```

Create instances and call their generated commands:

```zsh
source ./counter.zsh
z.cls.new Counter counter

counter.increment
counter.add 4
counter.count.get
print -r -- "$REPLY"  # 5

counter.count.set 10
counter.increment
print -r -- "$REPLY"  # 11

z.cls.delete counter
```

## References and variable scope

`z.cls.new Class variable` assigns an opaque instance reference to the named
variable and to `REPLY`, then marks the variable readonly. The binding follows
ordinary Zsh variable scope; assigning another reference or constructing again
in the same variable is rejected.
Declare the variable `local` in the caller to create a local binding:

```zsh
z.cls.new Counter counter
counter.count.set 10

example() {
  local counter=""
  z.cls.new Counter counter
  counter.increment
  print -r -- "$REPLY"  # 1
  z.cls.delete counter
}

example
counter.count.get
print -r -- "$REPLY"  # 10
```

Copying a reference shares the same instance. Reference expansion can invoke
its methods and accessors from any variable holding that reference:

```zsh
typeset -r other=$counter
"$other.increment"
"$other.count.get"
print -r -- "$REPLY"  # 11
```

The short form `counter.increment` resolves the currently visible `counter`
variable each time. The expanded form `"$other.increment"` calls through the
copied reference directly. A new instance requires a fresh binding, such as a
same-named `local` in an inner scope. Declare copied references with `typeset -r` or `local -r`
when they should also reject direct shell assignment.

`z.cls.delete variable` or `z.cls.delete "$reference"` releases the instance.
Reference bindings retain their readonly values after deletion; all references
to the deleted instance become invalid. Release instances explicitly when
finished; leaving a variable scope alone does not free their state.

## Definition and invocation rules

- Use one class definition at a time. Class names are unique in a shell.
- Names use letters, digits, and underscores, starting with a letter or
  underscore. The `z_cls_` prefix is reserved.
- Attribute defaults are scalar values, including empty strings. Attributes
  can become indexed or associative arrays in a method; their type and values
  are preserved between calls. Array setters accept their elements, and
  associative setters accept key/value pairs.
- Attribute names must be ordinary parameters. Zsh special parameters and
  `REPLY`/`reply` are reserved.
- New instance bindings must be writable ordinary scalar variables; creation
  makes them readonly. Their attributes remain mutable.
- Put `z.cls.fn name` and `z.cls.fn.done` on separate, unconditional statements.
  Quotes, comments, here-documents, pipelines, conditionals, and ordinary loops
  remain Zsh syntax inside the method.
- `z.cls.fn name 'body'` also accepts a short inline body.
- `z.cls.drew` publishes the class. `z.cls.abort` discards an unfinished
  definition. An unfinished method is discarded when execution leaves its
  defining source context.
- Arguments, standard output/error, `REPLY`, and exit status pass through.
  Attribute updates persist on explicit `return`, including nonzero status.
- Methods of one active instance share its restored attributes. Different
  instances remain independent. Reentering an active instance through a
  different instance's call is rejected.
- Ordinary shell process isolation applies to subshells and command
  substitutions. Use `REPLY` for results when mutations must persist.

## Public API and internal helpers

The public class API is draw, attr, fn, fn.done, drew, abort, new and delete.
Internal helper names have a final segment beginning with an underscore, following
z's completion convention. Shell completion and z-ls hide those helpers by default;
z-ls can include them with its showPrivateFunctions setting. This naming convention
does not restrict Zsh from calling the functions directly.

Shared z predicates validate integers, type flags, names and registry entries.
Shared collection getters preserve literal elements. Class accessors additionally
retain scalar-versus-array result shape and resolve attributes in their owning
scope through reserved internal parameter names.

## Runtime and editing

Method collection temporarily uses Zsh's DEBUG trap to record commands while
suppressing their execution. The previous function or list DEBUG handler and
the DEBUG timing / local-trap options are restored at the end marker. Existing
DEBUG handlers are suspended while collecting a body. Zsh reconstructs the
stored code, so comments and original formatting are not retained at runtime.

The definition file remains valid shell syntax for syntax highlighting and
body diagnostics.

## Runtime costs

Ordinary scalar accessors read or update only their saved value. Method calls
restore their attributes and save ordinary strings, decimal integers, indexed
arrays and associative arrays using parameter expansion. Uncommon parameter
flags use canonical typeset output from the attribute's own scope.

Generated command names keep their existing behavior. Their short programs
are cached by operation/member and copied with functions -c, which shares the
compiled program internally. This avoids storing and compiling an individual
body for every instance command. User replacements are compared against the
exact registered programs before cleanup.

Function-name entries and instance state still scale with the number of
instances and attributes. Method attribute copying remains proportional to the
attribute count and value size. Deleting instances releases their state, commands
and inactive-state entries.

After the last instance is deleted, empty instance tables are rebuilt to release
their capacity and unset lookup entries. Class definitions and shared command
programs remain cached for the shell session.

The allocator may keep freed memory for reuse by the same Zsh process, so RSS
need not return to its startup value. Process exit releases all of its memory.
Runtime cleanup uses ordinary Zsh and requires no native module.
