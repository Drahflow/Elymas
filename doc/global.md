Global functions
================


Many of the following functions can also be meaningfully applied to scopes. This would add nothing to understand though.
Hence, these effects are not discussed here, but in execution.md.


`/`
---

This is the identity function.

    1 / dump
    0000000000000001


`|`
---

Takes a name from the stack and resolves it. Disregarding possible execution modes, the
resolved object is never executed.

    "add" | dump
    <function: 00006000001019B0>
    |add dump
    <function: 00006000001019B0>


`?`
---

Implements the usual ternary operator.

    1 ==yesno
    # 0 =yesno
    yesno "Yesno was non-zero" "Yesno was zero" ? dump

This is particularly useful with function objects.

    yesno { "Now handling yes-case" dump }
          { "Now handling no-case" dump } ? *

`=`
---

Takes a name and a value from the stack. Assigns a new value to the name (which must
be defined before).

    0 ==i
    1 =i

`*`
---

Executes the top stack element. See execution.md for the full story.

    { "Hello World!" dump } *
    "Hello World!"

`[`
---

Puts an array-begin marker on the stack.


`]`
---

Scans the stack for the topmost array-begin marker and constructs an array containing all
objects between the marker and the stack top.

    [ /a /b /c ] dump
    [
      "a"
      "b"
      "c"
    ]

Note that the stack marker can be moved around with `-` like all other objects.

    /a [ -01 ] dump
    [
      "a"
    ]

`=[]`
-----

Assigns an array or string cell. It takes the array/string, the target index and the new value
from the stack.

    [ /a /b /c ] ==arr
    /X 1 arr =[]
    arr dump
    [
      "a"
      "X"
      "c"
    ]

`len`
-----

Takes an array or string from the stack and returns its length.

    "foo" len dump
    0000000000000003


`cat`
-----

Takes two arrays or strings from the stack and concatenates them.

    "foo" "bar" cat dump
    "foobar"


`dearray`
---------

Takes a length and an array from the stack and puts array indices from 0 to length (exclusive) on the stack.
During dereference, the array index is taken modulo the actual array length.

    [ /a /b /c ] _ len dearray
    dump dump dump
    "c"
    "b"
    "a"
    [ 1 0 ] 4 dearray
    dump dump dump dump
    0000000000000000
    0000000000000001
    0000000000000000
    0000000000000001

`range`
-------

Takes a end and a start value from the stack and creates an array containing all integers
from start to end (exclusive).

    0 4 range dump
    [
      0000000000000000
      0000000000000001
      0000000000000002
      0000000000000003
    ]

`<`
---

Switches to a new scope object which has the previous current scope as parent scope.


`>`
---

Pushes the current scope to the stack and switches the current scope to its parent.

    <
      0 ==i
    > .i dump
    0000000000000000


`>'`
----

Takes a scope object *p* from the stack. Pushes the current scope *s* onto the stack.
Sets the current scope to the parent of *s* and afterwards sets the parent of *s* to *p*.
See scopes.md for an example.


`scope`
-------

Pushes the current scope to the stack.

    <
      0 ==i
      scope keys dump > --
    [
      "i"
    ]


`die`
-----

Takes a string from the stack and outputs it to the standard error stream. Afterwards terminates the program.

    "Oops" die


`quoted`
--------

Returns the current quoting level of the parser. This is always 0 unless somehow invoked during evaluation of
some defq'ed code.

    { quoted dump } /q defq
    q
    0000000000000000
    { q } --
    0000000000000001
    { { q } } --
    0000000000000002
    { quoted dump } /p deff
    p
    0000000000000000
    { p } --
    { { p } } --
    { p } *
    0000000000000000
    { { p } } *
    dump
    <function: 00006000001B6740>


`def`-x family, `==?`, `=*?`, `==`, `=*`, `==:`, `=*:`
------------------------------------------------------

Takes a name and a value from the stack and maps the name to the value in the current scope. Depending on the
suffix of def, various execution and optimization modes are associated with the name. See scopes.md for details.


`''`
----

Takes a new output type, a new input type and a function object from the stack and returns a new function object
with the specified input and output types, executing the original function object. See execution.md about types.

    [ /a /ab /abc /abcd ] len dump
    0000000000000003
    [ /a /ab /abc /abcd ] |len [ 0 ] [ 0 ] '' * dump
    [
      0000000000000001
      0000000000000002
      0000000000000003
      0000000000000004
    ]

`'`
---

Like `''`, but instead of full specifications, just takes a string consisting of digits, a `.` and more
digits. The earlier digits specify scalar input types, the later digits specify scalar output types.

    [ /a /ab /abc /abcd ] len dump
    0000000000000003
    [ /a /ab /abc /abcd ] |len '0.0 * dump
    [
      0000000000000001
      0000000000000002
      0000000000000003
      0000000000000004
    ]
    
`'*`
----

A shortcut for `'<string> *`.

`;`
---

Concatenate two functions, i.e. take functions *g* and *f* from the stack and return a new function object which
executes *f* and then executes *g*.

    { 1 add } { 2 mul } ; /f deff
    3 f dump
    0000000000000008


`--`
----

Drops the top stack element.

    1 2 -- dump
    0000000000000001


`_`
---

Duplicates the top stack element.

    1 _ dump dump
    0000000000000001
    0000000000000001


`-`
---

Takes a string from the stack. This string may consist of digits and the `*` character. This string defines a stack
shuffling as follows. The highest digit plus one is the number of stack elements shuffled. The digits denote stack
elements, counting from top to bottom, i.e. `0` is stack top, `1` is next below `0` and so on. First all relevant
elements are removed from the stack, then the string is evaluated in order. Each digit pushes the respective element
back onto the stack, each `*` invokes the `*` function once.

    [ /a /b /c -1001 ] dump
    [
      "a"
      "b"
      "c"
      "c"
      "b"
    ]
    1 2 { 3 mul } -10*20* dump
    0000000000000003
    0000000000000006


`rep`
-----

Takes a function and a count from the stack. Executes the function as many times as specified.

    3 { /a dump } rep
    "a"
    "a"
    "a"


`loop`
------

Takes a function object *b* and a function object *p* from the stack. Then it executes *p* and takes
one integer from the stack. If this integer is non-zero, executes *b* and then restarts with executing *p*.
This repeats until *p* returns zero.

    0 ==i
    { i 3 lt } {
      i dump
      i 1 add =i
    } loop
    0000000000000000
    0000000000000001
    0000000000000002
    0 { _ 3 lt } { _ dump 1 add } loop
    0000000000000000
    0000000000000001
    0000000000000002


`each`
------

Takes a function object and an array or string from the stack. For each element of the array or string, pushes
that element, then executes the function.

    [ /a /b /c ] |dump each
    "a"
    "b"
    "c"


`.`
---

Takes a name and a scope from the stack. Resolves the name in the scope.

    < 5 ==i > .i dump
    0000000000000005


`.|`
----

Takes a name and a scope from the stack. Resolves the name in the scope, but never executes it.

    <
      1 ==i
      { 2 } =*j
    > ==s
    s .i dump
    0000000000000001
    s .j dump
    0000000000000002
    s .|i dump
    0000000000000001
    s .|j dump
    <function: 00006000008E5700>


`.?`
----

Takes a name and a scope from the stack. If the name can be resolved in the scope, returns 1, otherwise returns 0.

    < 0 ==i > ==s
    s .?i dump
    0000000000000001
    s .?j dump
    0000000000000000

`.?'`
-----

Takes a name and a scope from the stack. If the name can be resolved in the scope without its parent,
returns 1, otherwise returns 0.

    < 0 ==i > ==s
    s .?i dump
    0000000000000001
    s .?'i dump
    0000000000000001
    s .?s dump
    0000000000000001
    s .?'s dump
    0000000000000000


`keys`
------

Takes a scope object from the stack. Returns an array of the names defined directly in the scope.

    <
      0 ==i
      1 ==j
    > keys dump
    [
      "i"
      "j"
    ]


`dom`
-----

Takes an array or string from the stack, determines its length and returns an array containing
the integers from zero to length minus one. If the array or string would be a partial functions from
integers to elements, this is the domain of this function.

    "foo" dom dump
    [
      0000000000000000
      0000000000000001
      0000000000000002
    ]


`!!`
----

Takes a function object and creates a coroutine which resumes execution at the start of this function object.
The call and data stack of this new coroutine are initially empty. See coroutines.md for details and examples.


`!!'`
-----

Takes a function object *c* and a function object *m*. Creates a new coroutine which resumes execution at the start
of *c*. The call stack and data stack of this coroutine are copied from the current stack (after *c* and *m* have been
removed). Afterwards push the coroutine object and execute *m*. See coroutines.md for details and examples.


`!`
---

Takes a count and a target coroutine from the stack. Moves as many elements as specified from the current
stack to the stack of the specified coroutine. Additionally, push the current coroutine to the target coroutine's
stack. Then continue execution in the specified coroutine. See coroutines.md for details and examples.


`{`
---

Increases the parser quote level by one and pushes a quote begin marker onto the stack.


`}`, `}'`, `}"`, `}_`
---------------------

Decreases the parser quote level by one. Searches for the topmost quote begin marker on the stack and collects
all stack elements above it into a function object. See quoting.md for details.


`eq`
----

Takes two ints or strings from the stack. Returns one if they are equal, zero otherwise.


`neq`
-----

Takes two ints or strings from the stack. Returns one if they are non-equal, zero if they are.


`add`
-----

Adds two integers or floats.


`sub`
-----

Substracts two integers or floats.

    5 3 sub dump
    0000000000000002


`band`
------

Binary and between two integers.


`bor`
-----

Binary or between two integers.


`bxor`
------

Binary xor between two integers.


`gt`
----

Compares two integers or floats. If the first is greater than the second, return one, otherwise zero.

    4 5 gt dump
    0000000000000000
    5 5 gt dump
    0000000000000000
    6 5 gt dump
    0000000000000001


`ge`
----

Compares two integers or floats. If the first is greater than or equal to the second, return one, otherwise zero.

    4 5 gt dump
    0000000000000000
    5 5 gt dump
    0000000000000001
    6 5 gt dump
    0000000000000001


`lt`
----

Compares two integers or floats. If the first is less than the second, return one, otherwise zero.

    4 5 gt dump
    0000000000000001
    5 5 gt dump
    0000000000000000
    6 5 gt dump
    0000000000000000


`le`
----

Compares two integers or floats. If the first is less than or equal to the second, return one, otherwise zero.

    4 5 gt dump
    0000000000000001
    5 5 gt dump
    0000000000000001
    6 5 gt dump
    0000000000000000


`mul`
-----

Multiplies two integers or floats.

    2 3 mul dump
    0000000000000006
    2.0 3.0 mul dump
    +5.9999999999e0


`div`
-----

Divides two integers or floats. The integer version truncates the result towards zero.

    5 2 div dump
    0000000000000002
    5 2 neg div dump
    FFFFFFFFFFFFFFFE


`and`
-----

Logical and of two integers, i.e. one if both are non-zero, zero otherwise.


`or`
----

Logical or of two integers, i.e. one if any is non-zero, zero otherwise.


`xor`
-----

Logical xor of two integers, i.e. one if exactly one is non-zero, zero otherwise.


`bnot`
------

Bitwise integer negation.


`neg`
-----

Numerical integer negation.

    5 3 neg add dump
    0000000000000002


`not`
-----

Logical integer negation, i.e. one if zero previously, zero otherwise.


`regex`
-------

Takes a regular expression and a string from the stack. Matches the regular expression against the string.
If unsuccessful, returns a zero. If successful, pushes all subgroups in onto the stack, starting with the last.
Finally, pushes a one onto the stack.

    "The quick brown ..." "( ...).*(br.wn)" regex dump dump dump
    0000000000000001
    " qui"
    "brown"
    "The quick brown ..." "xxx" regex dump
    0000000000000000
    "The quick brown ..." { "(..)(.*)" regex } |dump loop
    "Th"
    "e "
    "qu"
    "ic"
    "k "
    "br"
    "ow"
    "n "
    ".."


`globals`
---------

Returns an array containing all names defined in the global scope.


`curry`
-------

Takes a typed function and curry it, i.e. return a function object which takes the last argument and returns a function
object which takes the second-to-last argument and returns a function object ... up to the final function object which
takes the first argument, executes the original function on all arguments thus acquired and returns the result.

    |sub curry ==a
    a dump
    <function: 00006000008379E0>
    2 a * ==b
    b dump
    <function: 0000600000832400>
    5 b * ==c
    c dump
    0000000000000003


`||`
----

First `|`, then `curry`. Resolves a name in the current scope and immediately curries the result.


`**`
----

Takes an object from the stack. If it is a function or an array, execute it. Then execute `**` again on the result.

    5 2 ||sub ** dump
    0000000000000003


`dump`
------

Takes an object from the stack and outputs some representation of it to the standard error stream.


`include`
---------

Takes a filename from the stack. Executes the content of the file as code in the current scope.


`via`
-----

Takes a name and a scope *s* from the stack. Constructs a new function which takes a string from the stack
and resolves it in *s*. `deffst`s this new function object to the name.

    <
      5 ==i
      { "hi" dump } =*greet
    > ":" via
    :i dump
    0000000000000005
    :greet
    "hi"


`fold`
------

Takes a function object and an array from the stack. Pushes the first array element. For each remaining element,
this element is first pushed and the function object then executed.

    [ /foo /bar /quux ] |cat fold dump
    "foobarquux"


`reverse`
---------

Reverses an array.

    [ /a /b /c ] reverse dump
    [
      "c"
      "b"
      "a"
    ]


`any`
-----

Takes an array. Returns one if any of its elements are non-zero.

    /b ==s
    [ /a /b /c ] s eq dump
    [
      0000000000000000
      0000000000000001
      0000000000000000
    ]
    [ /a /b /c ] s eq any dump
    0000000000000001

`all`
-----

Takes an array. Returns one if all of its elements are non-zero.

    [ 1 2 3 4 ] 5 lt all dump
    0000000000000001


`grep`
------

Takes a function object *p* and an array from the stack. Each element of the array in turn is pushed and *p* invoked.
Returns a new array consisting of those elements for which *p* returned non-zero.

    [ 1 2 3 4 5 6 ] { 2 mod } grep dump
    [
      0000000000000001
      0000000000000003
      0000000000000005
    ]


`indices`
---------

Takes a function object *p* and an array from the stack. Each element of the array in turn is pushed and *p* invoked.
Returns a new array consisting of those element indices for which *p* returned non-zero.

    [ /a /b /b /a /c ] { /a eq } indices dump
    [
      0000000000000000
      0000000000000003
    ]


`index`
-------

Takes a function object *p* and an array from the stack. Starting from the start of the array, each element is pushed
and *p* invoked. Returns the lowest array index for which *p* returns non-zero.

    [ /b /a /b /b /a ] { /a eq } index dump
    0000000000000001


`assert`
--------

Takes the top stack element. Terminates the program if it is zero.


`values`
--------

Takes a scope object. Returns an array consisting of the values of the scope's members.


`conds`
-------

Takes an array of function objects. Evaluates the objects at even indices. For the first of them returning non-zero,
execute the function object after it.

    { [
      { _ [ 5 3 ] mod not all } { "FizzBuzz" dump }
      { _ 3 mod not } { "Fizz" dump }
      { _ 5 mod not } { "Buzz" dump }
      { 1 } { dump }
    ] conds } ==f
    1 18 range f each
    0000000000000001
    0000000000000002
    "Fizz"
    0000000000000004
    "Buzz"
    "Fizz"
    0000000000000007
    0000000000000008
    "Fizz"
    "Buzz"
    000000000000000B
    "Fizz"
    000000000000000D
    000000000000000E
    "FizzBuzz"
    0000000000000010
    0000000000000011


`max`
-----

Takes two integers. Returns the larger one.


`min`
-----

Takes two integers. Returns the smaller one.
