Coroutines
==========

The current (userspace) program state of an elymas program consists of the
heap, the data stack, the call stack and the current instruction pointer. The
data stack is *the* stack, programs are manipulating all the time, whereas the
*call* stack holds information about what functions to return to after the
current one finishes and what the current local scope is.

The coroutine functions offer ways to create and switch to new program states
called *coroutines* which have separate call and possibly data stacks.

`!!`
----

This takes a function objects from the stack and initializes a new coroutine
with an empty call and data stack. This new coroutine is returned.

    { "Hello World" dump * } !! ==coroutine
    coroutine *
    "Hello World"


Calling Coroutines
------------------

Coroutines can be called either with `*`, in which only the call stack is switched, but
the same data stack is used as before the call. However, before the coroutine continues
execution, the coroutine from which the call originated is pushed to the data stack, so
the called coroutine can return to it (instead of running into an empty call stack at
the end of the execution).

Observe how execution switches between the coroutine and the implicit initial coroutine:

    { "Hello" dump * "World" dump * } !! ==coroutine
    coroutine * " " dump *
    "Hello"
    " "
    "World"

Alternatively, `!` can be used to call a coroutine and explicitely move items to the 
target coroutine's data stack.

    { ==ret "42" -01 { 1 } { "Holding:" dump -101 dump "Received:" dump dump ret 0 ! =ret } loop } !! ==coroutine
    "23"
    /foo coroutine 1 ! --
    "Holding:"
    "42"
    "Received:"
    "foo"
    /bar coroutine 1 ! --
    "Holding:"
    "42"
    "Received:"
    "bar"
    "On main stack:" dump dump
    "On main stack:"
    "23"


`!!'`
-----

The purpose of this function is to create coroutine with a cloned call stack. The created
coroutine will return to the call site of `!!'` after execution. However, the original
call will also return after `!!'` as usual, so to disambiguate the two more easily,
`!!'` takes two function objects. The topmost one *c* becomes the coroutine and pushed
to the data stack, the second argument then gets called in the usual fashion, thereby
receiving the coroutine version of *c* on the data stack.

Note how the greeting gets dumped twice as the coroutine continues execution after
`!!'`:

    {
      { } =*coroutine
      { =coroutine } { "coroutine" dump } !!'
      "Hello World" dump
      coroutine
    } *
    "Hello World"
    "coroutine"
    "Hello World"


Uses of Coroutines
------------------

One typical use of coroutines is separation between value generation and processing:

    { ==r
      1 1 { 1 } { _ r 1 ! =r -010 add } loop
    } !! { 0 ! -- }_ =*fib
    fib dump
    0000000000000001
    fib dump
    0000000000000002
    fib dump
    0000000000000003
    fib dump
    0000000000000005
    fib dump
    0000000000000008

While this seem a bit pointless in the example above, instead of calculating the fibonnacci
sequence, the coroutine might be tasked with more complex sequences, in particular ones where
local state is more complex than just two integers.

Another use case of coroutines is creating checkpoints in the code where execution can
restart if something goes wrong - or just because you love gotoesque execution flow:

    {
      {
        { } { -- restart } !!'
      } /restart deffd
      
      0 ==i
      
      restart ==checkpoint
      
      i 1 add =i
      i dump
      
      i 7 lt { checkpoint 0 ! } rep
    } *
    0000000000000001
    0000000000000002
    0000000000000003
    0000000000000004
    0000000000000005
    0000000000000006
    0000000000000007

A third use would be thread-like processing of network requests, in particular if network
sessions are stateful in a complex way.
