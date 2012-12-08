package ElymasSys;

use strict;
use warnings;

use Elymas;
use POSIX;

my $rwmask = &POSIX::O_RDONLY | &POSIX::O_WRONLY | &POSIX::O_RDWR;

our $sys = {
  'file' => [sub {
      my ($data) = @_;

      my $file = createFile(-1, &POSIX::O_RDONLY);
      push @$data, [enstruct($file)];
    }, ['func', 'sys .file'], 'active'],
  'in' => [enstruct(createFile(0, &POSIX::O_RDONLY)), 'passive'],
  'out' => [enstruct(createFile(1, &POSIX::O_WRONLY)), 'passive'],
  'err' => [enstruct(createFile(2, &POSIX::O_WRONLY)), 'passive'],
};

sub createFile {
  my ($fd, $flags) = @_;

  my $scope;
  $scope = \{
    ' fd' => [$fd, 'int', 'passive'],
    ' flags' => [$flags, 'int', 'passive'],
    ' mode' => [0777, 'int', 'passive'],
    'readonly' => [sub {
        $$scope->{' flags'}->[0] = ($$scope->{' flags'}->[0] & ~($rwmask)) | &POSIX::O_RDONLY;
      }, ['func', 'sys .file .readonly'], 'active'],
    'writeonly' => [sub {
        $$scope->{' flags'}->[0] = ($$scope->{' flags'}->[0] & ~($rwmask)) | &POSIX::O_WRONLY;
      }, ['func', 'sys .file .readonly'], 'active'],
    'readwrite' => [sub {
        $$scope->{' flags'}->[0] = ($$scope->{' flags'}->[0] & ~($rwmask)) | &POSIX::O_RDWR;
      }, ['func', 'sys .file .readonly'], 'active'],
    'open' => [sub {
        my ($data) = @_;

        die "file already open" unless $$scope->{' fd'}->[0] == -1;

        my $path = popString($data);

        my $fd = POSIX::open($path, $$scope->{' flags'}->[0], $$scope->{' mode'}->[0]);
        die "cannot open $path: $!" unless defined $fd;

        $$scope->{' fd'}->[0] = $fd;
      }, ['func', 'sys .file .open'], 'active'],
    'close' => [sub {
        die "file not open" if $$scope->{' fd'}->[0] == -1;

        my $ret = POSIX::close($$scope->{' fd'}->[0]);
        die "close failed: $!" unless defined $ret;

        $$scope->{' fd'}->[0] = -1;
      }, ['func', 'sys .file .close'], 'active'],
    'read' => [sub {
        my ($data) = @_;

        die "file not open" if $$scope->{' fd'}->[0] == -1;

        my $count = popInt($data);

        my $buf;
        my $ret = POSIX::read($$scope->{' fd'}->[0], $buf, $count);
        die "read failed: $!" unless defined $ret;

        $buf = [map { [ord, 'int'] } split //, $buf];

        push @$data, [$buf, ['array', '[]', [['range', 0, $#{$buf}]], ['int']]];
      }, ['func', 'sys .file .read'], 'active'],
    'readall' => [sub {
        my ($data) = @_;

        die "file not open" if $$scope->{' fd'}->[0] == -1;

        my $count = popInt($data);

        my $buf = [];
        while($count) {
          my $readbuf;
          my $ret = POSIX::read($$scope->{' fd'}->[0], $readbuf, $count);
          die "read failed: $!" unless defined $ret;

          $buf = [@$buf, map { [ord, 'int'] } split //, $readbuf];
          $count -= $ret;
        }

        push @$data, [$buf, ['array', '[]', [['range', 0, $#{$buf}]], ['int']]];
      }, ['func', 'sys .file .read'], 'active'],
    'write' => [sub {
        my ($data) = @_;

        die "file not open" if $$scope->{' fd'}->[0] == -1;

        my $buf = popArray($data);
        $buf = join '', map { chr($_->[0]) } @$buf;

        my $ret = POSIX::write($$scope->{' fd'}->[0], $buf, length $buf);
        die "write failed: $!" unless defined $ret;

        push @$data, [$ret, 'int'];
      }, ['func', 'sys .file .write'], 'active'],
    'writeall' => [sub {
        my ($data) = @_;

        die "file not open" if $$scope->{' fd'}->[0] == -1;

        my $buf = popArray($data);
        $buf = join '', map { chr($_->[0]) } @$buf;

        while($buf) {
          my $ret = POSIX::write($$scope->{' fd'}->[0], $buf, length $buf);
          die "write failed: $!" unless defined $ret;
          $buf = substr($buf, $ret);
        }
      }, ['func', 'sys .file .write'], 'active'],
  };

  return $$scope;
}

# sub installIntConstant {
#   my ($name) = @_;
# 
#   my $elymasName = $name;
#   $elymasName =~ s/_//g;
# 
#   $linux->{$elymasName} = [${$POSIX::{$name}}, 'int', 'passive'];
# }

1;
