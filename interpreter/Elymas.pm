package Elymas;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(popInt popString);

use Data::Dumper;

sub popInt {
  my ($data) = @_;

  my $i = pop @$data or die "Stack underflow";
  die "Not integer " . Dumper($i) unless $i->[1] eq 'int';
  return $i->[0];
}

sub popString {
  my ($data) = @_;

  my $s = pop @$data or die "Stack underflow";
  die "Not string " . Dumper($s) unless $s->[1] eq 'string';
  return $s->[0];
}

sub popArray {
  my ($data) = @_;

  my $a = pop @$data or die "Stack underflow";
  die "Not array: " . Dumper($a) unless ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array';

  return $a->[0];
}

1;
