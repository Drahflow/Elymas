System Interaction
==================

Some facilities have been developed to access the outside world.

`sys .exit`
-----------

Exists the program with the indicated error code.

    0 sys .exit       # successful termination


`sys .file`
-----------

Creates a scope representing a file. This object supports `.open`, `.close`, `.read`, `.write`, `.writeall`, `.eachLine`.
Three files `sys .in`, `sys .out`, `sys .err` are predefined and represent the standard input, output and error streams respectively.

    sys .file ":" via
      "foo.txt" :open
      8 :read dump          # first 8 bytes of foo.txt, possibly less if foo.txt is shorter
      { dump } :eachLine    # dump each line of foo.txt (excluding the 8 bytes already read)
      :close
    "Hallo Welt!\n" sys .out .writeall
    Hallo Welt!

As `.write` directly maps to the write(2) syscall, it might not write all bytes. Instead it returns the number of bytes written as an integer.
Usually, you want to use `.writeall` which will call write(2) repeatedly, until all bytes are written.

`sys .fdToFile` will create a file representing scope directly from a unix file descriptor number.


`sys .freeze`
-------------

To create stand-alone executables, `sys .freeze` takes a filename and a function object and creates an executable which will
execute the function object when started.

    { "Hello World!\n" sys .out .writeall 0 sys .exit } "hello" sys .freeze

An elymas interpreter can be implemented via `include` easily:

    {
      sys .argv len { 0 sys .argv * } { "/proc/self/fd/0" } ? * include
      0 sys .exit
    } "interpreter" sys .freeze


`sys .mkdir`
------------

Creates a new directory.


`sys .ls` / `sys .readdir`
--------------------------

List the contents of a directory. `sys .ls` excludes files with a leading dot.


`sys .rename`
-------------

Takes two filenames. Renames the first (stack second-to-top) to the second (stack top).
