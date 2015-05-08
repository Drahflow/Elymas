Scopes
======

A scope maps (variable) names to values. Each such binding also specifies how and when the referenced
object gets executed and what assumptions the optimizer may make about later values of the same name.
To create a mapping from a name to a value, various functions starting with `def` exist. Some of them
are aliased to `==` and similar functions.

They allow specifying four different execution modes:
* _v_alue: Upon dereference, the object is placed on top of the stack.
* _f_unction: Upon dereference, the object is executed (equivalently the object is placed on top of the stack, then `*` is executed).
* _m_ember: Upon dereference, the containing scope is pushed on the stack, then the object is executed.
* _q_uoting: The object is executed as soon as the name is encountered in the input stream, even if the parser is currently in quote
             mode.

They also allow specifying four different optimization guarantees:
* _s_tatic: The name always resides at the same scope slot. Scope slots are assigned deterministically. If the same set of variables
            is always declared in scopes encountered by a certain piece of code, then this piece of code can savely assume static
            names. This also guarantees that the execution mode of this name is always the same.
* _t_ype constant: The name always refers to the same type of object. If the variable held an integer once, it is required
                   to always hold an integer and so on. Arrays and functions are only type constant if they keep the same
                   function signature (i.e. same nesting depth in case of arrays).
* _c_onstant: The referenced object stays identical forever. This implies static and type constant.
* _d_eep constant: The referenced object and all objects reached through it (i.e. submembers in case of a scope) stay identical forever.
                   This implies constant.

No optimization guarantees can be specified for quoting execution mode, as optimization is not applied in this parsing stage.

The resulting function names are the concatenation of `def`, the desired execution mode character (`v`, `f`, `m`, `q`) and the
desired optimization guarantee (none, `s`, `t`, `st`, `c`, `d`).

This scheme results in 19 different functions. All of these functions take from the stack a name (on top of stack) and a value
to associate with the name.

    5 /five defv
    { "hi" dump } /greet deffst
    42 "ANSWER" defvd

Some of these functions are aliased, because they appear particularly useful:

* `==?` aliases `defv`, i.e. value definition without optimization guarantees
* `==` aliases `defvst`, i.e. value definition with static and type constness
* `==:` aliases `defvd`, i.e. value definition with deep constness
* `=*?` aliases `deff`, i.e. executable definition without optimization guarantees
* `=*` aliases `deffst`, i.e. executable definition with static and type constness
* `=*:` aliases `deffd`, i.e. executable definition with deep constness

The value associated with a name can be updated using the `=` function. It takes a name to update and the new value from the stack.

    0 ==i
    i 1 add =i
    i dump
    0000000000000001


Scope objects on the stack
--------------------------

There is always a current scope. This is the scope where lookup happens during code parsing and this is where the `def` function
family puts values. The current scope object can also be put on the stack using the `scope` function. All scope objects but the
global one have a single parent scope where lookup continues if a name can not be resolved in the scope itself.

The current scope can also be switched using `<` and `>`. `<` takes the current scope as the parent of a new scope which then
becomes current. `>` pushes the current scope to the stack and makes its parent the new current scope. This allows construction
of structured datatypes. To this end, the `.` function takes a name and a scope object from the stack and resolves the name in
the given scope object.

    <
      1 ==one
    > _ dump
    <scope: 00006000005DDAA0>
        .one dump
    0000000000000001

Function objects created by a `{`, `}` pair remember the scope they have been created in. Upon execution, they create a new
scope object which has this remembered scope as its parent. In effect, this results in closure semantics for function objects.

    <
      0 ==i
      { i dump i 1 add =i }
    > -- /dumpAndIncrement deffst
    dumpAndIncrement
    0000000000000000
    dumpAndIncrement
    0000000000000001
    dumpAndIncrement
    0000000000000002

Sometimes it's useful to assign a different parent pointer than the current scope to a new scope object. This can be
achieved by the `>'` function. It behaves like `>` but takes the parent pointer of the new object from the stack.

    <
      0 ==i
    > ==parent
    <
      { i dump i 1 add =i }
      parent
    >' -- /dumpAndIncrement deffst
    dumpAndIncrement
    0000000000000000
    dumpAndIncrement
    0000000000000001
    dumpAndIncrement
    0000000000000002

As `>'` only assigns the parent pointer when the scope stops being the current scope, before its execution the parent
was set as usual, i.e. the current scope before `<`. This allows for interesting possibilities. Note that names in
quoted mode are only resolved during first execution.
