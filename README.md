Elymas
======

*Just because I'm not following the true path, doesn't mean I can't get it to work.*

[![Build Status](https://travis-ci.org/Drahflow/Elymas.svg?branch=master)](https://travis-ci.org/Drahflow/Elymas)

Examples
--------

A programming language...

    1 dump
    # 0000000000000001

... stack based programming language ...

    1 2 add dump
    # 0000000000000003

... with array support ...

    [ 1 2 ] dump
    # [
    #   0000000000000001
    #   0000000000000002
    # ]

... did I mention array support ...

    2 [ 1 2 ] add dump
    [ 0 1 ] [ 1 2 ] add dump
    # [
    #   0000000000000003
    #   0000000000000004
    # ]
    # [
    #   0000000000000001
    #   0000000000000003
    # ]

... user definable functions ...

    { 2 add } /addTwo deffst
    1 addTwo dump
    # 0000000000000003

... variables ...
    
    2 ==two
    1 two add dump
    # 0000000000000003

... function objects ...

    { { 2 add } } /returnAddTwo deffst
    returnAddTwo /addTwo deffst
    1 addTwo dump
    # 0000000000000003

... closures ...

    { 2 ==two { two add } } /returnAddTwo deffst
    returnAddTwo /addTwo deffst
    1 addTwo dump
    # 0000000000000003

... structured data types ...

    <
      1 ==one
      2 ==two
    > ==struct

    struct keys dump
    struct .two dump

    # [
    #   "one"
    #   "two"
    # ]
    # 0000000000000002

... and more.

    "Elymas" { "(..)(.*)" regex } |dump loop

    # "El"
    # "ym"
    # "as"


Technical Pecularities
----------------------

* no runtime interpreter, executes real assembly
  * same binary both interpretes and compiles
* freeze arbitrary program states to ELF-binaries
* self hosted via `{ "/dev/stdin" include }' "interpreter" sys .freeze`
  * yes, this works and generates a stand-alone interpreter/compiler
  * bootstraps from perl
    * no perl left in final binaries
* macro support
* names carry information about being constant or constantly having the same type each resolution
  * just-too-late opcode optimization
  * so at least one resolution is guaranteed to have taken place
  * can declare names any time before first usage
* assembly optimizer realized as a loadable library
  * yes, it does optimize itself while running
* regex-engine written in the language itself
* source includes an assembler for 64bit x86


Features
--------

* non-braindead stack manipulation, e.g. `-021` specifies "top element, then third, then second"
* concatenative language syntax, e.g. `data modifyOne modifyTwo modifyThree`
* trivial to build DSLs
* compact code
  * more readable than APL though
  * unless you don't want it to be
* acceptable performance (and you can always switch to assembly if necessary)
* I actually use it for non-trivial projects

Documentation
-------------

Please see [the tutorial](doc/tutorial.md) for an introduction and further documentation.
