Foreign Function Interface
==========================

Elymas supports loading of shared object based libraries (`*.so`) utilizing the standard libc facilities.
This support is only available in the `shared` interpreter, which different from all other interpreters,
dynamically links against libc.

    sys .so ":" via
    "/lib/x86_64-linux-gnu/libm.so.6" :dlopen not { "Failed to load." die } rep
    "sin" "d" "d" :resolveFunction =*sin
    0 31 range { 10.0 div sin dump } each


`sys .so .dlopen`
-----------------

Takes a filename of a shared object from the stack and loads that shared object. A handle is returned
but can savely be ignored except to test it against zero, which would signify an error.

`sys .so .resolveFunction`
--------------------------

Takes a function name, a string describing function arguments and a string describing the return type
from the stack. It resolves the name within all currently loaded objects, and returns an elymas function
object which wraps the underlying foreign function.

The input specification string consists of single characters, each describing the type of one input
argument.

* `p` - A pointer argument.
* `i` - An integer (of any width).
* `f` - A float.
* `d` - A double.
* `s` - A string. A pointer to a zero-terminated string is passed to the C-function.
* `b` - A buffer. A pointer the beginning of the string contents is passed to the C-function.

When specifying the return type of the function, integer widths matter, hence the following
options are available.

* `v` - No return value
* `p` - Pointer return value
* `u8` - `uint8_t` return value
* `u16` - `uint16_t` return value
* `u32` - `uint32_t` return value
* `u64` - `uint64_t` return value
* `i8` - `int8_t` return value
* `i16` - `int16_t` return value
* `i32` - `int32_t` return value
* `i64` - `int64_t` return value
* `s` - String return value (will be copied)
* `f` - float return value
* `d` - double return value


`sys .so .rawContentAddress`
----------------------------

Returns the address of the first byte of a string. This can be handy to build complex C structures
within a string memory and then passing the pointer to a foreign function.

`sys .so .peekString`
---------------------

Takes an address and scans that address for a C-style zero-terminated string
(of some implementation defined maximum length). This string is subsequently returned.

`sys .so .freeze`
-----------------

A binary created by `sys .freeze` will have no dynamic dependencies, hence libc is not available. If you
want to use dynamic libraries in your binary, use `sys .so .freeze` which will create an ELF binary which
is dynamically linked against libc. The loaded libc is then used to call `dlopen` and `dlsym` to load
further libraries. The `shared` interpreter has been created with `sys .so .freeze`.


Libraries interfaced so far
---------------------------

* `ffi .pq` - PostgreSQL
