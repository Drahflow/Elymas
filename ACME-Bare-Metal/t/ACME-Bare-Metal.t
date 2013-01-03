# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl ACME-Bare-Metal.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 5;
BEGIN { use_ok('ACME::Bare::Metal') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $block = ACME::Bare::Metal::allocate(4096);
ok($block > 0, "Block allocation");

ACME::Bare::Metal::poke($block, 0xC3);
ok(ACME::Bare::Metal::peek($block) == 0xC3);

ACME::Bare::Metal::execute($block);
ACME::Bare::Metal::deallocate($block, 4096);

$block = ACME::Bare::Metal::allocateAt(4096, 0x0000700000000000);
ok($block > 0, "Block allocation");

ACME::Bare::Metal::poke($block, 0xC3);
ok(ACME::Bare::Metal::peek($block) == 0xC3);

ACME::Bare::Metal::execute($block);
ACME::Bare::Metal::deallocate($block, 4096);
