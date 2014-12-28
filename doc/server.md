Server Algorithms
=================

As a convenience for coding TCP/IP network servers some algorithms
are provided.

All these server templates work by first creating an object, then
configuring it via various setters, most importantly setting the
event handler for new connections and finally starting the event
loop. So far, all event loops are based on the epoll(7) facility.

net .alg .epollServer
---------------------

    net .alg .epollServer "+" via
     { 8000 } +port
     { ":" via
       # : provides methods to communicate with the new connection
       # :read, :write, :close, :ctl (as in EPOLL_CTL)
    
       "Welcome to server\n" :write
    
       <
         { 4096 :read _ dump "" eq { :close } rep } =*in
         { "Did't :ctl for outgoing data" die } =*out
         { "Error" die } =*err
       >
     } +accept
     +run

`net .alg .epollServer` creates a new server, on which the following options
can be set, and `accept` and `port` must be set before starting the server.

`port`: Takes a function which returns the port number to bind.

`accept`: Takes a function which takes a scope containing capabilities
to communicate over the newly accepted connection and returns a scope
which provides functions to call on `in`coming data, `out`going kernel
buffer space and `err`ors in the connection.

The capabilities of the connection are `read` which takes the maximal number of
bytes to read and returns a string of the actually read bytes or the empty string
if the connection ended. The member `write` takes a string and writes it to the
connection - returning the number of bytes written. `close` immediately closes
the connection and `ctl` takes a new set of flags `bor`'ed together from
`sys .linux .epoll .EPOLLIN`, `.EPOLLOUT`, and `.EPOLLERR` respectively.

`interval`: Takes a function which provides the number of microseconds to sleep
during the next epoll_wait(2) syscall.

    net .alg .epollServer "+" via { 1000 } +interval
    # server will abort epoll_wait after 1ms

`reuseAddr`: Takes a function which takes a socket file descriptor and performs
whatever shenanigans it deems appropriate before the socket is passed to bind(2).
The default for this option applies SO_REUSEADDR, hence the separate option, if you
whish to disable it set `reuseAddr` to `{ -- }`, i.e. just discard the socket descriptor.

    net .alg .epollServer "+" via { -- } +reuseAddr
    # server will not set SO_REUSEADDR

FIXME: There should be a general option setting option as well (and only the default-active
ones should be available for disabling)


net .alg .bufferedEpollServer (what you actually want to use)
-------------------------------------------------------------

Just as `net .alg .epollServer` and actually based on it, but provides buffering for all
in- and output so you don't have to track the number of bytes read and written and can
instead handle stuff on a higher level. To this end, `accept` works slightly different.

The capabilities `write`, `read`, `close` are provided as in `net .alg .epollServer`,
where `close` still immediately closes the connection, whereas the new capability
`finish` will first write the remaining output buffer bytes before actually closing
the connection.

The members of the `accept` returned scope are `in`, `err`, and `end`. The `in`
handler gets the current input buffer and is expected to return whatever can not
yet be handled (i.e. pars whatever prefix you like and return the rest), `err` is
called when an error occurs on the connection and `end` is called when the remote
end closes the connection.

`net .alg .bufferedEpollServer` takes the same options as `net .alg .epollServer`
and additionally provides `outputBufferLimit` which takes a function which
returns the maximum number of output buffer bytes you are willing to keep
around for slow reading clients.

    net .alg .bufferedEpollServer "+" via { 16 } +outputBufferLimit
    # server will raise an error if output buffer grows above 16 bytes


net .alg .httpServer
--------------------

This is not yet a full featured HTTP server, but works a little bit.
It is based on `net .alg .bufferedEpollServer` and takes the same options.
However, you are not supposed to provide an `accept`, but instead
call `request` to provide a function which handles the requests.

    net .alg .httpServer "+" via
      { 8080 } +port
      { ":" via
        # available methods are :ok, :fail, :close, :write, :finish
        # additional members are :headers, :method, :url, :args
        :headers keys dump
        :method dump
        :url dump
        :args keys dump
        "<html><body>O hi!</body></html>" "text/html" :ok
      } +request
      +run
