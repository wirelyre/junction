# Junction

Junction is a simple, familiar, safe programming language that's ready to
bootstrap.

🚧 It's also under construction, so please wear a hard hat. 🚧

- **simple:** Junction has only three built-in data types and simple control
  flow.

- **familiar:** Junction follows the traditions of Pascal and ML. It has
  automatic memory management, modules, and a complete type system.

- **safe:** The type system is strict; in return, well-formed programs (checked
  at compile time) will never encounter type errors, nor access memory unsafely.

- **ready to bootstrap:** Every feature, from syntax to checked generic types,
  has been designed to bootstrap cleanly from Topple, an earlier language, even
  though Junction is more sophisticated and far more comfortable to use.

```
mod example

use io.print
use std.range

print("Hello world!\n")

for n := range(1, 31) {
    if      (n % 15 == 0) { print("FizzBuzz") }
    else if (n %  5 == 0) { print("Buzz")     }
    else if (n %  3 == 0) { print("Fizz")     }
    else                  { print(n)          }

    print(" ")
}

print("\n")
```

## Roadmap

The current design is the result of several years of work (mostly done while
showering or hiking). I don't expect it to change much, although I'm quite happy
to make fundamental simplifications if possible.

Unfortunately it's mostly in my head.

The goal right now is to produce an interpreter so I can try writing a
self-compiler. Hopefully this will reveal any weaknesses I haven't found yet.
The process of writing this interpreter is important too, because bootstrapping
from Topple will be quite delicate, so I need to know how to write the bootstrap
incrementally.

Eventually I'll probably scrap the C runtime or rewrite it to resemble bytecode
found in another implementation.

- [x] Initial design
- [x] Experimental C runtime (found `<-` syntax)
- [ ] OCaml interpreter
  - Type checker?
- [ ] Library utilities (*e.g.* `List`, `HashSet`, `BigInt`, `Float64`)
- [ ] Self-compiler (targeting RISC-V)
- [ ] Topple bootstrap

And the final goal is to write a C compiler in Junction, completing my objective
of bootstrapping a C compiler from machine code and human-readable source code.

Junction's current design, though simple, is definitely enough to comfortably
write a C compiler. I'm excited to try.

## Language notes

### Syntax

No semicolons. Function calls `f(...)` are distinguished from expression
grouping `{...}`.

### Memory

All values are immutable. Values are only accessible after they are constructed.
Reference cycles are impossible. All memory is collected precisely using
reference counting.

Variables are mutable.

References to variables are written `^var`. References can only be created when
invoking a function, and they disappear when the function returns. They cannot
be stored in values. This prevents dangling references.

### Methods

Each concrete type has a method table (a module). Method calls `val->mthd(...)`
and `ref<-mthd(...)` use the method table of a specific value's type.

Reference method calls `ref<-mthd(...)` pass the receiver as a reference; their
signatures are `fn mthd(^self, ...)`. The compiler can update `^self` in place
if it has only one reference.

### Operators

The operators are `+ - * / %` (arithmetic), `| & !` (boolean), and
`== != < <= > >=` (comparison).

Arithmetic and boolean operator precedence follows their algebras: `a + b *
c == a + {b * c}`; and `a | !b & c == a | {{!b} & c}`. Arithmetic and boolean
operations cannot be mixed; they must be grouped with `{...}`.

Operators simply dispatch methods: `add`, `mul`, `not`, *etc*. The type and
names of comparison operators are undecided.

There is no short-circuiting control flow. Control flow uses keywords.

### Algebraic data types

```
type A(B | C(d: Nat, e: Bool))
# defines:
#   A   (module with method table)
#   A.B (value)
#   A.C (constructor with two fields)

let value: A = {...}

case value {
    B -> {...} # if value is B
    C -> {...} # if value is C
}
```

### Type parameters

Data types, functions, and traits can have type parameters:

```
type Vec2[T: Add](x: T, y: T)

trait Iterator[Item] {
    fn next(^self): Option[Item]
}

fn sum[T: Add, I: Iterator[T]](zero: T, iter: I): T {
    let total := zero
    for item := iter {
        total := total + item
    }
    total
}
```

All methods need a `self` or `^self` parameter. This trait is ill-formed: `trait
Default { fn default(): Self }`. Otherwise method dispatch would require type
analysis.

### Modules, functions, and scopes

Functions and modules are the same thing:

  - Files can have code at the top level, which is executed if the module is set
    as the entry point.

  - Functions export all the items contained inside, just like file-level
    modules. (As a side effect, all types are accessible from the global
    namespace, which prevents weird problems.)

Each `{...}` pair establishes a scope. `use`, `let`, `fn`, and `type` introduce
names that are valid until the containing `}`.

Declaration order *does* matter, but it's not a big deal. `use` statements
should be at the top of a scope. And if a name isn't defined, it's assumed to be
in the top-level module (*e.g.* `mod a.b.c {...} d()` calls `a.b.c.d()`).

## How to bootstrap

Assuming a program is well-formed, an interpreter can ignore types. In fact, it
can completely ignore the syntax `: SomeType` and `[Type, Parameters]`.

Values can carry around their method table. Generic types don't need to be
present at runtime, and an interpreter doesn't need to know the types of
variables and expressions.

Files can be compiled separately, and each in a single pass. Names are resolved
based only on source code earlier in the same file.

Because `{...}` scopes are simple and nested, variables are born and die in FIFO
order. Execution can be modeled as two stacks: one of temporaries, and one of
variables with random access. Even a simple compiler can have perfect automatic
memory management.

Native-code methods on the core data types `Array` and `Bytes` can use the
mutate-in-place optimization, even if no other functions or methods do.

Topple will need to be updated with its final feature: indirect (delayed)
execution. Then the Topple transpiler can produce the module namespace as
uninitialized variables, which can be defined and used in any order.
