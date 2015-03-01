Tutorial
========

This tutorial attempts to give a rough overview over the everyday syntax of Elymas.
It's main purpose is to make the rest of the documentation readable, in particular
to enable the reader to understand the examples given therein. It is by no means
a complete presentation of all features.


Getting started
---------------

First, you need an executable. 

    git clone https://github.com/Drahflow/Elymas.git
    cd Elymas && make

This should result in various executables. For the remainder of this tutorial, just use

    elymas/shared 

as it comes with all libraries preloaded. Start it and enter

    "Hello World!" dump

this should yield the obvious result or a bug report to the author.


Simple functions
----------------

Elymas is a stack based language. Instead of passing arguments to (and return values from)
functions explicitely, there is a global stack of data items all functions work upon.

One such function is `dump`. It takes the topmost value from the stack and outputs it to
the standard error stream.

    1 dump
    0000000000000001

Mathematical functions work similarly. They take arguments from the stack and leave the
result on top of the stack (where it can be consumed by `dump`).

    5 2 add dump
    0000000000000007
    5 2 sub dump
    0000000000000003
    5 2 mul dump
    000000000000000A
    5 2 div dump
    0000000000000002
    5 2 mod dump
    0000000000000001


Strings
-------

There are two common ways to create a string on the stack.

    "This is a string" dump
    "This is a string"
    /thisToo dump
    "thisToo"

Strings can contain some escapes using backslash.

    "Two\nlines" dump
    "Two
    lines"
    "\\" dump
    "\"


Function objects
----------------

Multiple functions (and constants) can be combined into one function by enclosing them
in braces. The resulting objects reside on the stack just like all other values.
The function `*` executes such function objects.

    { 5 add } dump
    <function: 00006000005E0360>
    3 { 5 add } * dump
    0000000000000008


Variables
---------

Variables can be declared and at the same time assigned by `==`.

     2 ==two
     two two add dump
     0000000000000004
     { 2 add } ==addTwo
     2 addTwo * dump
     0000000000000004


Scopes
------

Variables live in scopes which are hierarchically nested. Every scope has a parent scope,
except the topmost (global) scope. If a variable is not found in a scope, its parent is
queried for it. Every function object execution creates a fresh scope, in effect allowing
local variables.

    2 ==two
    { ==i two i add } ==addTwo
    2 addTwo * dump
    0000000000000004
    3 addTwo * dump
    0000000000000005

Scopes can also be created explicitely using `<` and `>`. Variables in such an explicit
scope are accessed through `.`.

    < 2 ==two > dump
    <scope: 0000600000553A20>
    < 2 ==two > .two dump
    0000000000000002


Stack manipulation
------------------

It is often helpful to rearrange values on the stack, for example because a function
expects arguments in a different order. The function `-` does this.

    /a /b /c dump dump dump
    "c"
    "b"
    "a"
    /a /b /c -0012 dump dump dump dump
    "a"
    "b"
    "c"
    "c"

The digits after the `-` refer elements of the stack, `0` denotes the topmost element,
`1` the next one and so on until `9`. The function `_` finally is identical to `-00`,
i.e. it duplicates the topmost element. It exists separately, because this use is so
common.

    /a _ dump dump
    "a"
    "a"


Other useful functions
----------------------

`/` is the identity function.

    1 / dump
    0000000000000001


Recommended reading order
-------------------------

* parsing.md - how the input gets interpreted
* scopes.md - where variables live
* global.md - global functions
* execution.md - executing things
* quoting.md - function definition
* container.md - containers other than arrays
* sys.md - some interfaces to the operating system
* err.md - error handling
* conventions.md - naming conventions
* server.md - ready-made TCP/IP server templates
* ffi.md - foreign function interface
