package ElymasAsm;

use strict;
use warnings;

use Elymas;
use ACME::Bare::Metal;

our $asm = {
  'alloc' => [sub {
      my ($data) = @_;

      my $size = popInt($data);
      my $block = ACME::Bare::Metal::allocate($size);

      my $scope; $scope = \{
        'base' => [$block, 'int', 'passive'],
        'size' => [$size, 'int', 'passive'],
        'free' => [sub {
          my ($data) = @_;

          ACME::Bare::Metal::deallocate($$scope->{'base'}->[0], $$scope->{'size'}->[0]);
        }, ['func', 'sys .asm .free'], 'active'],
      };

      push @$data, [enstruct($$scope)];
    }, ['func', 'sys .asm .alloc'], 'active'],
  'poke' => [sub {
    my ($data, $scope) = @_;

    my $addr = popInt($data);
    my $value = popInt($data);

    ACME::Bare::Metal::poke($addr, $value);
  }, ['func', 'sys .asm .poke', ['int', 'int'], []], 'active'],
  'peek' => [sub {
    my ($data, $scope) = @_;

    my $addr = popInt($data);
    my $value = ACME::Bare::Metal::peek($addr);

    push @$data, [$value, 'int'];
  }, ['func', 'sys .asm .peek', ['int'], ['int']], 'active'],
  'execute' => [sub {
    my ($data, $scope) = @_;

    my $addr = popInt($data);

    ACME::Bare::Metal::execute($addr);
  }, ['func', 'sys .asm .execute'], 'active'],
};
