Quoting - how functions are made
================================

The behavior of the input parser depends on an integer counter, the *quote level*. If the quote level is zero,
each identifier is resolved in the current scope and acted upon (i.e. either pushed to the stack or executed depending
on the execution mode of the name). If, however, the quote level is non-zero, only those names which have the quoting
execution mode associated get executed. For all other names, a new function is instead created and pushed to the stack.
This function will upon execution look up the name and only then act upon it. This allows easy construction of complex
function objects.

In particular the functions `{` and `}` have quoting execution mode and are hence always executed directly when encountered.
The `{` function puts a function-quote-begin marker on the stack and increases the quote level by one. A later `}` then collects
all stack contents up to the function-quote-begin marker from the stack and creates assembly instructions from them. These
instructions will esentially execute the collected functions. After that `}` decrements the quote level and checks for zero.
If zero has been reached, a new function object is created from the assembled instructions and the current scope and pushed
to the stack. If the quote level is still non-zero after `}`, a new function is instead created which will upon execution
create a new function object from the instructions and the then current scope.

An example might make everything a little clearer:

    1 1 add dump       # instant execution of `add`
    0000000000000002
    { 1 1 add } dump   # a function object is created
    <function: 00006000005D5600>
    { 1 1 add } * dump
    0000000000000002

The function `quoted` returns the current quote level and can be very useful for creating macros. For now however, let's just
use it to make the example a little clearer.

    { "===" dump quoted dump _ dump } /debug defq     # define a helper function showing current quote level and stack top
                                                      # note that this function has quote execution mode
    1 debug 1 debug add debug
    "==="
    0000000000000000
    0000000000000001
    "==="
    0000000000000000
    0000000000000001
    "==="
    0000000000000000
    0000000000000002

    { 1 debug 1 debug add debug } debug
    "==="
    0000000000000001              # inside the { the quote level is 1
    0000000000000001              # constants are still pushed literally
    "==="
    0000000000000001
    0000000000000001
    "==="
    0000000000000001
    <function: 000060000062DEA0>  # but the add has been pushed as a function
    "==="
    0000000000000000
    <function: 00006000005CE300>  # this is the resulting function object

    { { 1 1 debug } debug } * dump
    "==="
    0000000000000002              # the nested { resulted in a quote level of 2
    0000000000000001
    "==="
    0000000000000001
    <function: 00006000006A4250>  # this is the output of debug, showing a function object 6A4250...
    <function: 00006000006A6EE0>  # which is different from the one ultimately representing { 1 1 }

Why are the two function objects in the last example different? Consider repeated executions of `{ { 1 1 } }`. Each invokation of the outer
function should result in a new inner function object. Hence it is not pushed as a literal, but a function object is created (for inclusion
in the outer braces) which will create a new inner function object on each execution. In principle, these implicitely created function
objects can be assigned to variables and executed like all others.

    { 3 } =*value         # define a function always returning 3
    { } =*f               # predefine a function variable
    { _ =f } /get defq    # grab a function object into f
    { value get } --      # f now contains the function resolving value
    value dump
    0000000000000003
    <
      { 5 } /value deff   # redefine value, always return 5
      f dump
    0000000000000005      # notice how the new value is being used
    >
    value dump            # and the global one again gets resolved
    0000000000000003


How instructions are assembled
------------------------------

How exactly does `}` assemble instructions? First it searches the stack for the topmost function-quote-begin marker. From there on towards
the stack top, each element is considered in turn. If it is a literal (i.e. integer, string or float) an instruction is created pushing
the same literal. If it is a function object, an instruction is created calling that function (if necessary switching the current scope to
the captured scope of the function beforehand and back after execution).

Additionally, `}` adds a function header and footer to the instruction sequence. The header creates a new scope for the duration of the
execution, while the footer switches back to the earlier scope again. This effectively results in local variable semantics for newly
defined variables.


What a function object contains
-------------------------------

Each function object can refer to
* its instruction sequence
* its captured scope
* its expected input and output arguments

When a function starts executing, the current scope is switched to the captured scope. Afterwards the instruction sequence will create
a new scope as a child of this now current scope. At the end of the function this child scope is exited. Afterwards the calling function
will switch the scope back to where it was before execution began.

The function `}'` and `}"` allow construction of function objects with less scoping effects. This can be useful to create functions with
unusal effects with respect to scopes. While `}'` creates a function which captures the enclosing scope but does not create a new child
scope, `}"` neither captures the scope nor creates a new child. In effect the contents of `}'` will execute in the parent scope of the
function definition while the contents of `}"` will execute in the scope of the calling site.

    <
      { == }' /set deff   # capture enclosing scope and execute == within it
      { == }" /SET deff   # capture nothing
    > ==s
    s keys dump
    [
      "set"
      "SET"
    ]
    0 /foo s .set         # execute set, i.e. execute == in the scope where { == } was written
    s keys dump
    [
      "set"
      "SET"
      "foo"
    ]
    0 /bar s .SET         # execute SET, i.e. execute == in the current scope
    s keys dump
    [
      "set"
      "SET"
      "foo"
    ]
    bar dump              # bar has been defined in the global scope
    0000000000000000


`}_`
----

The `}_` function is a macro defined in terms of `}`. It first creates a function just as `}`. Afterwards it also consumes the stack top
element and combines it with the just created function object into a new function object which pushes the captured stack element before
executing the created function.

    { { add }_ } /makeAdder deff
    5 makeAdder /addFive deff
    3 addFive dump
    0000000000000008

Understanding the source code of `}_` in compiler/standerd.ey is actually a very worthwile exercise for understanding the quoting rules
of elymas.
