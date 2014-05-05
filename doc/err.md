Error handling
==============

The easiest way to deal with errors in elymas is the `die` function. It takes a string, dumps it to the
error output and terminates the program. It might however be preferable to act more gracefully if problems
are encountered. To this end, an error handling library was created.

The main idea is to have the error locations suggest possible further actions from which the calling
function can then select a suitable one depending on circumstances. To give an example: While it would be
perfectly ok to terminate the program on a failed `sys .read` in a single-user command line application,
the same can certainly not be said about a webserver. However the code of `sys .read` cannot possibly know
how to react correctly.

The error handling does not automatically rewind the stack like it is usual in many other languages. If such
behaviour is desired, it can be emulated via coroutines.

Usually, different kinds of errors need different handling. Hence most functions take a string describing the
kind of error which occured. This string is always treated as a prefix of a possibly more detailed description.
If an error of (hypthetical) kind "io.write.diskfull" is raised, a handling routine for "io.write" will catch it,
as would a handler for "io".


`??`
----

Takes a string and raises an error of the specified kind.

    ??fatal.testError

`???`
-----

Takes a string and a scope and raises an error of the kind specified by the string. The scope members
are possible ways to react to the error provided to upper layers of the application.

    < { "ignored" dump } =*ignore { "oops" die } =*terminate > ???fatal.testError


`?!`
----

Specifies behavior if an error occurs. Takes to function objects. The first is executed. If an error occurs
during its execution, the second is invoked with the error handling scope provided on the stack.

    {
      < { "ignored" dump } =*ignore { "oops" die } =*terminate > ???fatal.testError
    } /maybeFailFunction deff
    |maybeFailFunction { .terminate } !?fatal # handle all fatal.* errors by the .terminate action


`??!`
-----

Specifies behavior if an error occurs by mapping a lower level error to a higher level one.

    { ... } # do stuff to the database
    { ==lowLevelHandlers <      # capture handling proposals from lower levels
      { ... } =*rollback        # provide new suggestions how to handle the error ...
      { ... } =*closeDatabase   # possibly using low-level suggestions while doing so
      { ... } =*terminate
    > ??!io.database } ?!io     # map all io.* errors do io.database errors


`??!'`
------

Just like `??!`, but does not take a string. Instead it re-raises the original error kind string.


`?!!`
-----

Applies an array of error handling strategies in turn.

    { ... } # do stuff to the database
    [
      { .rollback }                        # try the .rollback handler suggested by lower level
      { .closeDatabase }                   # if it raises an error again, try the .closeDatabase handler
      { "cannot recover from error" die }  # if this in turn fails, just die
    ] ?!!io.database                       # apply above rules to any io.database.* errors


`!!?`
-----

Clones the current coroutine state and returns it. This allows resetting the stack and
instruction pointer to an earlier state.

    [ "config.xml" "config.xml.bak" "config.xml.orig" ] ==configFiles
    0 ==currentConfig
    !!? ==checkpoint                      # clone current coroutine state
    {
       currentConfig configFiles * parse ...
    } {                                   # on error:
      --                                  # ignore lower level suggestions 
      currentConfig 1 add =currentConfig  # try a different config file
      currentConfig configFiles len lt {
        checkpoint 0 !                    # rewind execution back to checkpoint
      } rep                               # ... if candidates remain
    } ?!io                                # apply above rules to any io.* errors
