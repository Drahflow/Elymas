package ElymasLinux;

use strict;
use warnings;

use Elymas;

use POSIX ();

our $linux = {
  'open' => [sub {
      my ($data, $scope) = @_;

      my $mode = popInt($data);
      my $flags = popInt($data);
      my $pathname = popString($data);

      my $fd = POSIX::open($pathname, $flags, $mode);
      $fd = -1 unless defined $fd;

      push @$data, [$fd, 'int'];
    }, ['func', 'linux .open'], 'active'],
  'close' => [sub {
      my ($data, $scope) = @_;

      my $fd = popInt($data);

      my $ret = POSIX::close($fd);
      $ret = -1 unless defined $ret;

      push @$data, [$ret, 'int'];
    }, ['func', 'linux .close'], 'active'],
#  'read' => [sub {
#      my ($data, $scope) = @_;
#
#      my $count = popInt($data);
#      my $buf = popArray($data);
#      my $fd = popInt($data);
#
#      my $ret = POSIX::close($fd);
#      $ret = -1 unless defined $ret;
#
#      push @$data, [$ret, 'int'];
#    }, ['func', 'linux .read'], 'active'],
};

map { installIntConstant($_) } qw(O_RDONLY O_RDWR O_WRONLY);

sub installIntConstant {
  my ($name) = @_;

  my $elymasName = $name;
  $elymasName =~ s/_//g;

  $linux->{$elymasName} = [${$POSIX::{$name}}, 'int', 'passive'];
}

1;
