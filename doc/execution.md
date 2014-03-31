Executing things
----------------


Objects are executed on various occasions in a program. The most obvious example is `*`, but similarly
execution happens for resolved names which have the executing mode set in their scope (otherwise, `*` not
never get to execute in the first place), or as part of other functions like `each`.

The following examples tend to only highlight `*` based execution, but the same principles apply whenever
things are executed.


Main philosophy
---------------

*If the programmer typed it, there must be a way to make sense of it.*

In general, most things can be executed. In particular, all things which in some way map inputs to outputs
do so via execution.

    5 3 |add * dump
    0000000000000008
    1 [ /a /b /c /d ] * dump
    "b"
    1 "abcd" * dump
    0000000000000062
    map ==m
    2 /foo m =[]
    3 /bar m =[]
    /foo m * dump
    0000000000000002
    list ==l
    /a l .append
    /b l .append
    /c l .append
    1 l * dump
    "b"


Arrays indices start at zero and wrap around.

    1 [ /a /b /c ] * dump
    "b"
    2 [ /a /b /c ] * dump
    "c"
    3 [ /a /b /c ] * dump
    "a"
    4 [ /a /b /c ] * dump
    "b"

Some executable things have a type attached which specifies how many arguments they expect and return
(and of which types in turn these arguments are - but this is still quite broken). These types are just
arrays of concrete examples of the expected type. All scalar data types (i.e. integers and floats) are
represented by integers. `add` expects two scalars and returns one scalar.

    |add sys .typed .inputs dump
    [
      0000000000000000
      0000000000000000
    ]
    |add sys .typed .outputs dump
    [
      0000000000000000
    ]


When typed things are executed on other executable things (instead on the expected scalars) and if these
other executable things expect a single input, an honest attempt is made to apply them elementwise and
construct as result an objects resembling the input. If some elements are less-dimensional
(in case of arrays, but the principle generalizes) they are replicated (or made constant functions) as necessary.

    [ 1 2 3 ] [ 1 2 3 ] add dump
    [
      0000000000000002
      0000000000000004
      0000000000000006
    ]
    [ 1 2 3 ] 1 add dump
    [
      0000000000000002
      0000000000000003
      0000000000000004
    ]
    1 [ 1 2 3 ] add dump
    [
      0000000000000002
      0000000000000003
      0000000000000004
    ]
    [ [ 1 2 3 ] [ 4 5 6 ] ] 3 add dump
    [
      [
        0000000000000004
        0000000000000005
        0000000000000006
      ]
      [
        0000000000000007
        0000000000000008
        0000000000000009
      ]
    ]
    [ 1 0 2 0 ] [ [ 1 2 3 4 ] [ 5 6 7 8 ] ] mul dump
    [
      [
        0000000000000001
        0000000000000000
        0000000000000006
        0000000000000000
      ]
      [
        0000000000000005
        0000000000000000
        000000000000000E
        0000000000000000
      ]
    ]
    |not |not add _ ==f dump
    <function: 00006000006A1770>
    1 f * dump
    0000000000000000
    0 f * dump
    0000000000000002
    |add curry 3 add _ ==f dump
    <function: 00006000001B26E0>
    1 2 f * * dump
    0000000000000006
    ||add |not add _ ==f dump
    <function: 0000600000905130>
    2 1 f ** dump
    0000000000000003
    1 1 f ** dump
    0000000000000002
    0 1 f ** dump
    0000000000000002


A new type can be assigned with the `''` function, which takes the new output type, the new input type and the original
function object from the stack and creates a new function object with the assigned types.

    { } [ 5 ] [ 7 ] '' _ sys .typed .inputs dump
                         sys .typed .outputs dump
    [
      0000000000000005
    ]
    [
      0000000000000007
    ]


When constructing the result object, a choice must be made between constructing arrays (or whatever datatype) or functions. 
If any argument has an explicit `dom`ain, this domain is taken for the result. If no such domain can be determined, a
function object is created.

    { 2 mod } [ 0 ] [ 0 ] '' [ 1 2 3 4 5 6 ] mul dump
    [
      0000000000000000
      0000000000000002
      0000000000000000
      0000000000000004
      0000000000000000
      0000000000000006
    ]
    { 2 mod } [ 0 ] [ 0 ] '' { [ 1 2 3 4 5 6 ] * } [ 0 ] [ 0 ] '' mul _ dump
    <function: 00006000005CC7E0>
    =*f
    0 f dump
    0000000000000000
    1 f dump
    0000000000000002
    2 f dump
    0000000000000000
    [ 3 4 5 ] |f [ 0 ] [ 0 ] '' * dump
    [
      0000000000000004
      0000000000000000
      0000000000000006
    ]
    map ==m
    2 /foo m =[]
    3 /bar m =[]
    4 /quux m =[]
    m 2 mul _ dump
    <scope: 00006000005C5280>
    ==n
    /foo n * dump
    0000000000000004
    n dom dump
    [
      "foo"
      "bar"
      "quux"
    ]
    n dom n * dump
    [
      0000000000000004
      0000000000000006
      0000000000000008
    ]
    
(FIXME: There will be a `'` function soonish, which will abbreviate the common cases of `''` for scalar functions.)
(FIXME: A lot of the more interesting cases don't work, yet. Many a SIGSEGV will have to be removed before this is as
epic as it should be.)


Execution of and with scopes
----------------------------

Most global functions can be applied to scopes. When this happens a corresponding member of the scope is resolved instead.
Usually this member takes the form `#name` for a global function `name`. If the scope is not the first argument to a function
(but the first scope argument), then the resulting member name is something like `#-021 name` where the digits give the
stack manipulation of `-` which would be necessary to put the object back to the correct stack position.


    <
      { 5 } "#len" deff
    > len dump
    0000000000000005
    <
      { 5 add } "#add" deff
    > ==s
    2 s add dump
    0000000000000007
    <
      { _ add } "#*" deff
    > ==s
    2 s * dump
    0000000000000004
    <
      { 2 add } "#-01 add" deff
    > 5 add dump
    0000000000000007

The member function `#*` is used whenever an execution of the scope would be required.


To correctly handle the application of a typed function to a scope representing a container data
type, a few more members are needed. At least these are
* `#*` - to read elements of the container
* `#=[]` - to write elements of the container
* `#in` - to determine the input type of the scope, will usually just be `{ [ 0 ] }`
* `#out` - to determine the output type of the scope, will usually just be `{ [ 0 ] }`
But usually, the container will have a finite domain, and a new container needs to be constructed
for the result. This is handled by
* `#each` - applies a function to each of the containers values
* `#dom` - returns the concrete, finite domain
* `#istart` - returns an object to iterate over the container contents, pointing to the first, usually an integer
* `#istep` - takes such an iterator object and points it to the next container element
* `#iend` - takes an iterator object and returns non-zero if it points after the last element, i.e. the end of the container has been reached
* `#itrans` - takes an iterator object and transforms it into an element of the container's domain. This will often be the identity function.
* `#iclone` - creates a new container object which can assing via `=[]` elements for the entire original domain.

See elymas/lib/map.ey for an example.


(FIXME: Scopes will also be able to define member functions `#.`, `#.|`, `#.?` and `#.=` to handle references to non-existing name slots.
This does not yet work correctly with the optimizer.)
