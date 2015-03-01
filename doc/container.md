Container Types
===============

Lists
-----

A list maps integers to arbitrary objects. Access to members takes time linear in the index.

A new list can be created with `list` and appended to with `append` or `append1` (the latter
will not distribute over domain having inputs).

    list ==l
    /a l .append
    /b l .append
    /c l .append
    l dump
    <scope: 0000600000533210>
    l |dump each
    "a"
    "b"
    "c"
    l len dump
    0000000000000003
    list ==m
    [ /a /b /c ] m .append1
    m len dump
    0000000000000001

Lists can be used similar to functions from integers or arrays. Just as with
arrays, negative indices start from the end of the list towards the beginning.
Write access is provided via `=[]` as usual.

    list ==l
    [ /a /b /c ] l .append
    0 l * dump
    "a"
    1 neg l * dump
    "c"
    l dom dump
    [
      0000000000000000
      0000000000000001
      0000000000000002
    ]
    /foo 1 l =[]
    l |dump each
    "a"
    "foo"
    "c"
    l l { cat } '*0.0 |dump each
    "aa"
    "bb"
    "cc"

List can be used like a stack via `pop`.

    list ==l
    [ /a /b /c ] l .append
    l .pop
    l |dump each
    "a"
    "b"

Maps
----

Maps wrap scopes to provide an array-like container mapping from strings to arbitrary objects.

A new map can be created with `map`, new members are added via `=[]` when the key does not exist
beforehand. Access to specific members works like in arrays via `*`. Testing for members can be
done via `has`.

    map ==m
    1 /foo m =[]
    2 /bar m =[]
    m dump
    <scope: 0000600000533210>
    m dom dump
    [
      "foo"
      "bar"
    ]
    m |dump each
    0000000000000001
    0000000000000002
    /foo m * dump
    0000000000000001
    /foo m .has dump
    0000000000000001
    /FOO m .has dump
    0000000000000000
    m 2 mul ==m2
    m2 dom dump
    [
      "foo"
      "bar"
    ]
    m2 |dump each
    0000000000000002
    0000000000000004
    /foo m2 * dump
    0000000000000002

Trees
-----

Trees provide mapping from keys to arbitrary objects,
keeping the keys in `lt`/`eq`/`gt` ascending order. Otherwise they should work just as maps.

    tree ==t
    1 /foo t =[]
    2 /bar t =[]
    t dump
    <scope: 0000600000533210>
    t dom dump
    [
      "bar"
      "foo"
    ]
    t |dump each
    0000000000000002
    0000000000000001
    /foo t * dump
    0000000000000001
    /foo t .has dump
    0000000000000001
    /FOO t .has dump
    0000000000000000
    t 2 mul ==t2
    t2 dom dump
    [
      "bar"
      "foo"
    ]
    t2 |dump each
    0000000000000004
    0000000000000002
    /foo t2 * dump
    0000000000000002
