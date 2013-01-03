#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <sys/mman.h>


MODULE = ACME::Bare::Metal		PACKAGE = ACME::Bare::Metal		

void *
allocate(length)
    int length
  CODE:
    RETVAL = mmap(0, length, PROT_EXEC | PROT_READ | PROT_WRITE,
      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    OUTPUT:
      RETVAL

void *
allocateAt(length, addr)
    int length
    void *addr
  CODE:
    RETVAL = mmap(addr, length, PROT_EXEC | PROT_READ | PROT_WRITE,
      MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
    OUTPUT:
      RETVAL

void
deallocate(block, length)
    void *block
    int length
  CODE:
    munmap(block, length);

void
poke(addr, data)
    void *addr
    int data
  CODE:
    *((unsigned char *)addr) = (unsigned char)data;

int
peek(addr)
    void *addr
  CODE:
    unsigned char buf = *(unsigned char *)addr;
    RETVAL = buf;
  OUTPUT:
    RETVAL

void
execute(block)
    void *block
  CODE:
    ((void (*)(void))block)();
