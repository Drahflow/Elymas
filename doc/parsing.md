Parsing
=======

Elymas has a very simplistic parser (if at all). Parsing works as follows:
* Spaces separates things.
* If a `#` is encountered, ignore rest of line. This implements comments.
* If a sequence of digits is encountered, this is an integer literal and gets
  pushed to the stack.
* If something looks like a float, i.e. matches (\\d[0-9.]*([eE]-?\\d+)?),
  this is a float literal and gets pushed to the stack.
* If a `"` is encountered, a string literal begins. Within a string, backslash
  escapes special characters. `\\` becomes single backslash, `\n` is a new line,
  `\r` is a carriage return, `\0` is the NUL character (all bits zero). All
  other (non-escaped) characters just become part of the string.
* If a sequence of alphanumeric characters (a-zA-Z0-9) is encountered,
  it is looked up in the current scope. This is how normal functios like `dump`
  get referenced.
* If a sequence of non-alphanumeric characters is encountered,
  it is looked up in the current scope. This is how functions like `_` work.
* If a sequence starts with non-alphanumeric characters, but then an alphanumeric
  character is encountered, this latter part is converted to a string literal
  (backslash escapes do not apply) and pushed to the stack. Afterwards the
  non-alphanumeric prefix is looked up in the current scope. This is how
  `/abc` becomes `"abc"`: The string is created during parsing and afterwards
  the identity function is applied.
