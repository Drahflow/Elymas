package ElymasGlobal;

use strict;
use warnings;

use Elymas;
use ElymasSys;

use Data::Dumper;

our $global = {
  '/' => [sub { }, ['func', '/'], 'active'],
  '|' => [sub {
      my ($data, $scope) = @_;

      my $n = pop @$data or die "Stack underflow";
      my $meaning = resolve($$scope, $data, $n->[0]);
      if(not defined $meaning) {
        die "could not resolve '$n->[0]'";
      }
      push @$data, [$meaning->[0], $meaning->[1]];
    }, ['func', '|'], 'active'],
  '\\' => [sub {
      my ($data, $scope) = @_;

      my $n = pop @$data or die "Stack underflow";
      my $meaning = resolve($$scope, $data, $n->[0]);
      if(not defined $meaning) {
        die "could not resolve '$n'";
      }
      execute([$meaning->[0], $meaning->[1]], $data, $scope);
    }, ['func', '\\'], 'active'],
  '{' => [sub {
      my ($data, $scope) = @_;
      ++$quoted;
      push @$data, ['{', 'tok', '{'];
    }, ['func', '{'], 'quote'],
  '}' => [sub {
      my ($data, $refScope) = @_;
      my $scope = $$refScope;

      --$quoted;

      my @code;
      while(1) {
        my $t = pop @$data or die "Stack underflow";
        last if($t->[1] eq 'tok' and $t->[0] eq '{');

        unshift @code, $t;
      };

      die "unexpanded token in quoted code" if grep { $_->[1] eq 'tok' } @code;

      if($quoted) {
        push @$data, [sub {
          my ($data, $refScope) = @_;
          my $scope = $$refScope;

          push @$data, [sub {
            my ($data) = @_;
            my $lscope = \{ ' parent' => $scope };
            interpretCode(\@code, $data, $lscope);
          }, ['func', 'Dumper(\@code)']];
        }, ['func', 'func-quoted'], \@code];
      } else {
        push @$data, [sub {
          my ($data) = @_;
          my $lscope = \{ ' parent' => $scope };
          interpretCode(\@code, $data, $lscope);
        }, ['func', 'Dumper(\@code)']];
      }
    }, ['func', '}'], 'quote'],
  "}'" => [sub {
      my ($data, $refScope) = @_;
      my $scope = $$refScope;

      --$quoted;

      my @code;
      while(1) {
        my $t = pop @$data or die "Stack underflow";
        last if($t->[1] eq 'tok' and $t->[0] eq '{');

        unshift @code, $t;
      };

      die "unexpanded token in quoted code" if grep { $_->[1] eq 'tok' } @code;

      if($quoted) {
        push @$data, [sub {
          my ($data, $refScope) = @_;
          my $scope = $$refScope;

          push @$data, [sub {
            my ($data) = @_;
            interpretCode(\@code, $data, \$scope);
          }, ['func', 'Dumper(\@code)']];
        }, ['func', 'func-quoted'], \@code];
      } else {
        push @$data, [sub {
          my ($data) = @_;
          interpretCode(\@code, $data, \$scope);
        }, ['func', 'Dumper(\@code)']];
      }
    }, ['func', '}'], 'quote'],
  'quoted' => [sub {
      my ($data, $scope) = @_;
      push @$data, [$quoted? 1: 0, 'int'];
    }, ['func', 'quoted'], 'active'],
  '--' => [sub {
      my ($data, $scope) = @_;
      pop @$data;
    }, ['func', '-'], 'active'],
  '-' => [sub {
      my ($data, $scope) = @_;

      my $spec = popString($data);
      my $max = 0;

      my @spec = split //, $spec;
      $max = $_ > $max? $_: $max foreach grep { $_ ne '*' } @spec;

      my @buffer;
      foreach (0 .. $max) {
        die "Stack underflow" unless @$data;
        push @buffer, pop @$data;
      }

      foreach my $i (@spec) {
        if($i eq '*') {
          my $f = pop @$data or die "Stack underflow in '-*'";
          execute($f, $data, $scope);
        } else {
          push @$data, $buffer[$i];
        }
      }
    }, ['func', '-'], 'active'],
  '_' => [sub {
      my ($data, $scope) = @_;

      my $x = pop @$data or die "Stack underflow";
      push @$data, $x;
      push @$data, $x;
    }, ['func', '_'], 'active'],
  '*' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow in '*'";
      execute($f, $data, $scope);
    }, ['func', '*'], 'active'],
  ';' => [sub {
      my ($data, $scope) = @_;

      my $g = pop @$data or die "Stack underflow";
      my $f = pop @$data or die "Stack underflow";
      
      push @$data, [sub {
          my ($data, $scope) = @_;

          execute($f, $data, $scope);
          execute($g, $data, $scope);
        }, ['func', 'f g ;']];
    }, ['func', ';'], 'active'],
  '[' => [sub {
      my ($data, $scope) = @_;
      push @$data, ['[', 'tok'];
    }, ['func', '['], 'active'],
  ']' => [sub {
      my ($data, $scope) = @_;

      my @content;
      my $type = undef;
      while(1) {
        my $t = pop @$data or die "Stack underflow";
        last if($t->[1] eq 'tok' and $t->[0] eq '[');

        if($type) {
          if(ref($type) eq 'ARRAY' and $type->[0] eq 'func') {
            # TODO permitted for now
          } elsif(ref($type) eq 'ARRAY' and $type->[0] eq 'array') {
            # TODO permitted for now
          } elsif(ref($type) eq 'ARRAY' and $type->[0] eq 'struct') {
            # TODO permitted for now
          } else {
            die "mismatched types in array: " . Dumper($type, $t) unless typeEqual($type, $t->[1]);
          }
        } else {
          $type = $t->[1];
        }

        unshift @content, $t;
      };

      push @$data, [\@content, ['array', '[]', [['range', 0, $#content]], [$type]]];
    }, ['func', ']'], 'active'],
  '<' => [sub {
      my ($data, $scope) = @_;
      $$scope = { ' parent' => $$scope };
    }, ['func', '<'], 'active'],
  '>' => [sub {
      my ($data, $scope) = @_;

      push @$data, [$$scope, ['struct']];
      $$scope = $$scope->{' parent'};
    }, ['func', '>'], 'active'],
  '.' => [sub {
      my ($data, $scope) = @_;

      my $member = pop @$data;
      my $struct = pop @$data;
      $member = $member->[0];

      die "not a struct during member dereference in " . Dumper($struct) unless ref($struct->[1]) eq 'ARRAY' and $struct->[1]->[0] eq 'struct';
      die Dumper($struct, [sort keys $struct->[0]], $member) . "Cannot resolve requested member $member" unless exists $struct->[0]->{$member};
      die "Resolved member $member was incorrectly stored as something non-arrayish" unless ref($struct->[0]->{$member}) eq 'ARRAY';

      if($struct->[0]->{$member}->[2] eq 'active') {
        execute($struct->[0]->{$member}, $data, $scope)
      } else {
        push @$data, [$struct->[0]->{$member}->[0], $struct->[0]->{$member}->[1]];
      }
    }, ['func', '.'], 'active'],
  '.|' => [sub {
      my ($data, $scope) = @_;

      my $member = popString($data);
      my $struct = pop @$data;

      die "not a struct during member dereference in $struct" unless $struct->[1]->[0] eq 'struct';
      die Dumper($struct, $member) . "Cannot resolve requested member $member" unless exists $struct->[0]->{$member};

      push @$data, $struct->[0]->{$member};
    }, ['func', '.|'], 'active'],
  'deff' => [sub {
      my ($data, $scope) = @_;

      my $name = pop @$data or die "Stack underflow";
      my $func = pop @$data or die "Stack underflow";

      $$scope->{$name->[0]} = [@$func, 'active'];
    }, ['func', 'deff'], 'active'],
  'defv' => [sub {
      my ($data, $scope) = @_;

      my $name = pop @$data or die "Stack underflow";
      my $func = pop @$data or die "Stack underflow";

      $$scope->{$name->[0]} = [@$func, 'passive'];
    }, ['func', 'defv'], 'active'],
  'defq' => [sub {
      my ($data, $scope) = @_;

      my $name = pop @$data or die "Stack underflow";
      my $func = pop @$data or die "Stack underflow";

      $$scope->{$name->[0]} = [@$func, 'quote'];
    }, ['func', 'defq'], 'active'],
  '=' => [sub {
      my ($data, $scope) = @_;

      my $name = pop @$data or die "Stack underflow";
      my $func = pop @$data or die "Stack underflow";

      my $meaning = resolve($$scope, $data, $name->[0]);
      if(not $meaning) {
        $$scope->{$name->[0]} = [@$func, 'passive'];
      } else {
        $meaning->[0] = $func->[0];
        $meaning->[1] = $func->[1];
      }
    }, ['func', 'defv'], 'active'],
  'code' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow";
      my $code = $f->[2];

      my $res = 0;
      if(defined $code and not ref($code)) {
        $res = 1;
      } elsif(defined $code and ref($code) eq 'ARRAY') {
        $res = 2;
      }

      push @$data, [$res, 'int'];
    }, ['func', 'code'], 'active'],
  'sym' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow";
      my $str = $f->[2];
      die "not in fact code" unless defined $str;
      die "code not a symbol" if ref($str) eq 'ARRAY';

      push @$data, [$str, 'string'];
    }, ['func', 'sym'], 'active'],
  'blk' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow";
      my $block = $f->[2];
      die "not in fact code" unless defined $block;
      die "code not a block" unless ref($block) eq 'ARRAY';

      push @$data, [$block, ['array', '... blk', [['range', 0, $#{$block}]], [undef]]];
    }, ['func', 'blk'], 'active'],
  'rep' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow";
      my $c = pop @$data or die "Stack underflow";

      die "Not numeric: " . Dumper($c) unless $c->[1] eq 'int';

      foreach my $i (1 .. $c->[0]) {
        execute($f, $data, $scope);
      }
    }, ['func', 'rep'], 'active'],
  '?' => [sub {
      my ($data, $scope) = @_;

      my $b = pop @$data or die "Stack underflow";
      my $a = pop @$data or die "Stack underflow";
      my $p = pop @$data or die "Stack underflow";

      push @$data, ($p->[1] eq 'int' and $p->[0] == 0? $b: $a);
    }, ['func', '?'], 'active'],
  'include' => [sub {
      my ($data, $scope) = @_;

      my $s = popString($data);

      executeFile($s, $data, $scope);
    }, ['func', 'include'], 'active'],
  'regex' => [sub {
      my ($data, $scope) = @_;

      my $rx = popString($data);
      my $s = popString($data);

      my @result = $s =~ qr($rx)s;
      if(not @result) {
        push @$data, [0, 'int'];
      } elsif(($result[0] & ~ $result[0]) eq "0") {
        push @$data, [1, 'int'];
      } else {
        foreach my $m (reverse @result) {
          push @$data, [$m, 'string'];
        }
        push @$data, [1, 'int'];
      }
    }, ['func', 'regex'], 'active'],
  'cat' => [sub {
      my ($data, $scope) = @_;

      my $b = pop @$data or die "Stack underflow";
      my $a = pop @$data or die "Stack underflow";

      if(ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array') {
        if(ref($b->[1]) eq 'ARRAY' and $b->[1]->[0] eq 'array') {
          my $commonType;

          if(not typeEqual($a->[1]->[3]->[0], $b->[1]->[3]->[0])) {
            if(not @{$a->[0]}) {
              $commonType = $b->[1]->[3]->[0];
            } elsif(not @{$b->[0]}) {
              $commonType = $a->[1]->[3]->[0];
            } elsif(not exists $a->[1]->[3]->[0]) {
              $commonType = $b->[1]->[3]->[0];
            } elsif(not exists $b->[1]->[3]->[0]) {
              $commonType = $a->[1]->[3]->[0];
            } elsif($a->[1]->[3]->[0]->[0] eq 'func' and $b->[1]->[3]->[0]->[0] eq 'func') {
              # TODO: compare the function types maybe
            } else {
              die "Array types don't match in cat: " . Dumper($a, $b);
            }
          } else {
            $commonType = $a->[1]->[3]->[0];
          }

          my @res = (@{$a->[0]}, @{$b->[0]});
          if(defined $commonType) {
            push @$data, [\@res, ['array', 'from cat', [['range', 0, $#res]], [$commonType]]];
          } else {
            push @$data, [\@res, ['array', 'from cat', [['range', 0, $#res]]]];
          }
        } else {
          die "Mismatch between string and array in cat";
        }
      } elsif($a->[1] eq 'string') {
        if($b->[1] eq 'string') {
          push @$data, [$a->[0] . $b->[0], 'string'];
        } else {
          die "Mismatch between string and array in cat";
        }
      } else {
        die "Neither string nor array: " . Dumper($a);
      }
    }, ['func', 'cat'], 'active'],

# not really part of the spec, this is just for debugging
  'dump' => [sub {
      my ($data, $scope) = @_;

      my $d = pop @$data or die "Stack underflow";
      print Dumper($d);
    }, ['func', 'dump'], 'active'],
  'die' => [sub {
      my ($data, $scope) = @_;

      my $d = pop @$data or die "Stack underflow";
      die Dumper($d); # , $scope);
    }, ['func', 'die'], 'active'],
  'keys' => [sub {
      my ($data, $scope) = @_;

      my $s = pop @$data or die "Stack underflow";

      if(ref($s->[1]) eq 'ARRAY' and $s->[1]->[0] eq 'struct') {
        my @keys = grep { /^[^ ]/ } keys %{$s->[0]};

        push @$data, [[map { [$_, 'string'] } @keys], ['array', '[]', [['range', 0, $#keys]], ['string']]];
      } else {
        die "keys not supported on this value: " . Dumper($s);
      }
    }, ['func', 'keys'], 'active'],
  'strToUTF8Bytes' => [sub {
      my ($data, $scope) = @_;

      my $str = popString($data);

      my @res = map { [ord, 'int'] } split //, $str;
      push @$data, [\@res, ['array', 'from strToUTF8Bytes', [['range', 0, $#res]], ['int']]];
    }, ['func', 'strToUTF8Bytes'], 'active'],

# stuff from J
  'sig' => [sub {
      my ($data, $scope) = @_;

      my $v = pop @$data or die "Stack underflow";
      die "Not numeric: " . Dumper($v) unless $v->[1] eq 'int';

      push @$data, -1 if $v->[0] < 0;
      push @$data, 0 if $v->[0] == 0;
      push @$data, 1 if $v->[0] > 0;
    }, ['func', 'sig'], 'active'],
  'len' => [sub {
      my ($data, $scope) = @_;

      my $a = pop @$data or die "Stack underflow";
      if(ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array') {
        push @$data, [scalar @{$a->[0]}, 'int'];
      } elsif($a->[1] eq 'string') {
        push @$data, [length $a->[0], 'int'];
      } else {
        die "Neither string nor array: " . Dumper($a);
      }
    }, ['func', 'len'], 'active'],
  '=[]' => [sub {
      my ($data, $scope) = @_;

      my $a = pop @$data or die "Stack underflow";
      my $i = pop @$data or die "Stack underflow";
      my $v = pop @$data or die "Stack underflow";
      die "Not array: " . Dumper($a) unless ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array';
      die "Not numeric: " . Dumper($i) unless $i->[1] eq 'int';
      die "Type mismatch between value and array in assignment: " . Dumper($v, $a)
        unless canCastTo($v->[1], $a->[1]->[3]->[0]);
      my $idx = $i->[0];

      $idx += @{$a->[0]} while($idx < 0);
      $idx = $idx % @{$a->[0]};

      $a->[0]->[$idx] = $v;
    }, ['func', '=[]'], 'active'],
  'dearray' => [sub {
      my ($data, $scope) = @_;

      my $c = pop @$data or die "Stack underflow";
      my $a = pop @$data or die "Stack underflow";
      die "Not numeric: " . Dumper($c) unless $c->[1] eq 'int';
      die "Not array: " . Dumper($a) unless ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array';

      foreach my $i (0 .. $c->[0] - 1) {
        push @$data, $a->[0]->[$i % @{$a->[0]}];
      }
    }, ['func', 'dearray'], 'active'],
  'each' => [sub {
      my ($data, $scope) = @_;

      my $f = pop @$data or die "Stack underflow";
      my $a = pop @$data or die "Stack underflow";
      die "Not array: " . Dumper($a) unless ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array';

      foreach my $i (@{$a->[0]}) {
        push @$data, $i;
        execute($f, $data, $scope);
      }
    }, ['func', 'each'], 'active'],
  'range' => [sub {
      my ($data, $scope) = @_;

      my $e = pop @$data or die "Stack underflow";
      my $s = pop @$data or die "Stack underflow";
      die "Not numeric: " . Dumper($e) unless $e->[1] eq 'int';
      die "Not numeric: " . Dumper($s) unless $s->[1] eq 'int';

      $s = $s->[0];
      $e = $e->[0];

      push @$data, [[map { [$_, 'int'] } $s .. $e], ['array', '[]', [['range', 0, $e - $s]], ['int']]];
    }, ['func', 'seq'], 'active'],
  'loop' => [sub {
      my ($data, $scope) = @_;

      my $b = pop @$data or die "Stack underflow";
      my $t = pop @$data or die "Stack underflow";

      while(1) {
        execute($t, $data, $scope);

        my $c = pop @$data or die "Stack underflow";
        die "Not numeric: " . Dumper($c) unless $c->[1] eq 'int';
        last unless $c->[0];

        execute($b, $data, $scope);
      }
    }, ['func', 'loop'], 'active'],
  'dom' => [sub {
      my ($data, $scope) = @_;

      my $a = pop @$data or die "Stack underflow";

      if(ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'array') {
        my $l = @{$a->[0]};

        push @$data, [[map { [$_, 'int'] } 0 .. $l - 1], ['array', '[]', [['range', 0, $l - 1]], ['int']]];
      } elsif(ref($a->[1]) eq 'ARRAY' and $a->[1]->[0] eq 'struct') {
        die "no supporting dom member in struct" . Dumper($a) unless exists $a->[0]->{'dom'};

        if($a->[0]->{'dom'}->[2] eq 'active') {
          execute($a->[0]->{'dom'}, $data, $scope)
        }
      } else {
        die "dom not supported on this value: " . Dumper($a);
      }
    }, ['func', 'dom'], 'active'],
  'exe' => [sub {
      my ($data, $scope) = @_;

      push @$data, $globalCallStack[-2];
    }, ['func', 'rec'], 'active'],
  'sys' => [$ElymasSys::sys, ['struct'], 'passive'],
};

sub installGlobal1IntFunction {
  my ($name, $code) = @_;

  $global->{$name} = [sub {
      my ($data, $scope) = @_;

      my $a = popInt($data);
      push @$data, [&$code($a), 'int'];
    }, ['func', $name, ['int'], ['int']], 'active'];
}

sub installGlobal2IntFunction {
  my ($name, $code) = @_;

  $global->{$name} = [sub {
      my ($data, $scope) = @_;

      my $b = pop @$data;
      unless($b->[1] eq 'int' and $data->[-1]->[1] eq 'int') {
        die "Not int-typed arguments: " . Dumper($data->[-1], $b);
      }
      $data->[-1] = [&$code($data->[-1]->[0], $b->[0]), 'int'];

#      my $b = popInt($data);
#      my $a = popInt($data);
#      push @$data, [&$code($a, $b), 'int'];
    }, ['func', $name, ['int', 'int'], ['int']], 'active'];
}

sub installGlobal2StrFunction {
  my ($name, $code) = @_;

  $global->{$name} = [sub {
      my ($data, $scope) = @_;

      my $b = popString($data);
      my $a = popString($data);
      push @$data, &$code($a, $b);
    }, ['func', $name, ['int', 'int'], ['int']], 'active'];
}

# math and logic stuff
installGlobal2IntFunction('add', sub { return $_[0] + $_[1] });
installGlobal2IntFunction('sub', sub { return $_[0] - $_[1] });
installGlobal2IntFunction('mul', sub { return $_[0] * $_[1] });
installGlobal2IntFunction('div', sub { return int($_[0] / $_[1]) });
installGlobal2IntFunction('mod', sub { return $_[0] % $_[1] });

installGlobal2IntFunction('and', sub { return ($_[0] and $_[1])? 1: 0 });
installGlobal2IntFunction('nand', sub { return (not ($_[0] and $_[1]))? 1: 0 });
installGlobal2IntFunction('or', sub { return ($_[0] or $_[1])? 1: 0 });
installGlobal2IntFunction('xor', sub { return ($_[0] xor $_[1])? 1: 0 });
installGlobal2IntFunction('nxor', sub { return (not ($_[0] xor $_[1]))? 1: 0 });
installGlobal2IntFunction('nor', sub { return (not ($_[0] or $_[1]))? 1: 0 });

installGlobal2IntFunction('band', sub { return (0 + $_[0]) & (0 + $_[1]) });
installGlobal2IntFunction('bnand', sub { return ~((0 + $_[0]) & (0 + $_[1])) });
installGlobal2IntFunction('bor', sub { return (0 + $_[0]) | (0 + $_[1]) });
installGlobal2IntFunction('bxor', sub { return (0 + $_[0]) ^ (0 + $_[1]) });
installGlobal2IntFunction('bnxor', sub { return ~((0 + $_[0]) ^ (0 + $_[1])) });
installGlobal2IntFunction('bnor', sub { return ~((0 + $_[0]) | (0 + $_[1])) });

installGlobal2IntFunction('eq', sub { return ($_[0] == $_[1])? 1: 0 });
installGlobal2IntFunction('neq', sub { return ($_[0] != $_[1])? 1: 0 });
installGlobal2IntFunction('lt', sub { return ($_[0] < $_[1])? 1: 0 });
installGlobal2IntFunction('le', sub { return ($_[0] <= $_[1])? 1: 0 });
installGlobal2IntFunction('gt', sub { return ($_[0] > $_[1])? 1: 0 });
installGlobal2IntFunction('ge', sub { return ($_[0] >= $_[1])? 1: 0 });

installGlobal2IntFunction('gcd', sub { my ($a, $b) = @_; ($a, $b) = ($b, $a % $b) while($b); return $a; });

installGlobal1IntFunction('neg', sub { return -$_[0] });
installGlobal1IntFunction('not', sub { return not $_[0] });
installGlobal1IntFunction('bnot', sub { return ~(0 + $_[0]) });
installGlobal1IntFunction('abs', sub { return abs $_[0] });

# FIXME: this API is ugly
installGlobal2StrFunction('streq', sub { return [($_[0] eq $_[1])? 1: 0, 'int'] });

# J comparison (http://www.jsoftware.com/docs/help701/dictionary/vocabul.htm)
# = Self-Classify • Equal              -> <TODO redundant> / eq
# =. Is (Local)                        -> <nope>
# =: Is (Global)                       -> <nope>

# < Box • Less Than                    -> <nope> / lt
# <. Floor • Lesser Of (Min)           -> <TODO: float> / { _10 lt ? }
# <: Decrement • Less Or Equal         -> { 1 - } / le
# > Open • Larger Than                 -> <nope> / gt
# >. Ceiling • Larger of (Max)         -> <TODO: float> / { _10 gt ? }
# >: Increment • Larger Or Equal       -> { 1 + } / ge

# _ Negative Sign / Infinity           -> neg / <TODO: float>
# _. Indeterminate                     -> <TODO: floats>
# _: Infinity                          -> <TODO: floats>
#  
# + Conjugate • Plus                   -> <TODO: complex> / add
# +. Real / Imaginary • GCD (Or)       -> <TODO: complex> / gcd
# +: Double • Not-Or                   -> { 2 * } / nor
# * Signum • Times                     -> sig / mul
# *. Length/Angle • LCM (And)          -> <TODO: complex> / { |mul *10 gcd div }
# *: Square • Not-And                  -> { _ mul } / nand
# - Negate • Minus                     -> neg / sub
# -. Not • Less                        -> not / <TODO: all elements of a which are not also in b>
# -: Halve • Match                     -> { 2 div } / <TODO: recursive equal>
# % Reciprocal • Divide                -> { 1 -01 div } / div
# %. Matrix Inverse • Matrix Divide    -> <TODO matrix solve>
# %: Square Root • Root                -> <TODO: floats>

# ^ Exponential • Power                -> <TODO: exp> / <TODO: pow>
# ^. Natural Log • Logarithm           -> <TODO: ln> / <TODO: log>
# ^: Power (u^:n u^:v)                 -> rep / <TODO: understand J>

# $ Shape Of • Shape                   -> <TODO: think about abstract shapes and reshaping>
# $. Sparse                            -> <nope>
# $: Self-Reference                    -> { <depth> rec }
# ~ Reflex • Passive / Evoke           -> { _ } / { -01 } / { | }
# ~. Nub •                             -> <TODO: implement "uniq">
# ~: Nub Sieve • Not-Equal             -> <TODO: implement "uniq-idx"> / ne
# | Magnitude • Residue                -> abs / mod
# |. Reverse • Rotate (Shift)          -> <TODO: think about abstract reverse> / <TODO: think about abstract rotate>
# |: Transpose                         -> <TODO: think about abstract transpose implementation>
#  
# . Determinant • Dot Product          -> <TODO: implement the algorithm>
# .. Even                              -> { -20*1*21* add 2 div }
# .: Odd                               -> { -20*1*21* sub 2 div }
# : Explicit / Monad-Dyad              -> <nope> / <nope>
# :. Obverse                           -> <TODO: think of inverse functions>
# :: Adverse                           -> <TODO: think about error handling>
# , Ravel • Append                     -> <TODO: create array of submost elements> / <TODO: think about abstract append>
# ,. Ravel Items • Stitch              -> <TODO: explicit 1-level mapping of ,>
# ,: Itemize • Laminate                -> <TODO: implementable without new primitives>
# ; Raze • Link                        -> <nope (this be unboxing stuff)>
# ;. Cut                               -> <TODO: implement said algorithms, but use separate functions>
# ;: Words • Sequential Machine        -> <TODO: think about providing lexing / sequential machine support>
#  
# # Tally • Copy                       -> { len } / <TODO: implementable without new primitives>
# #. Base 2 • Base                     -> <TODO: implement rebase: multiply then add, left atom is made into list, left list is multiplied up, try to do it without primitives>
# #: Antibase 2 • Antibase             -> <TODO: implement antibase, try to do it without primitives>
# ! Factorial • Out Of                 -> <TODO: factorial and binomial coefficients, possibly without primitives>
# !. Fit (Customize)                   -> <nope>
# !: Foreign                           -> <TODO: wrap stuff from man 2>
# / Insert • Table                     -> { =f _ len =l l dearray f l 1 sub rep } / <FIXME: create (only)-non-identical types and casts>
# /. Oblique • Key                     -> <TODO: implement this without new primitives> / <TODO: implement with out new primitives>
# /: Grade Up • Sort                   -> <TODO: implement grade and sort with basic primitives, create generic version> / <TODO: implement order with basic primitives>
# \ Prefix • Infix                     -> <TODO: implement without new primitives> / <TODO: implement without new primitives>
# \. Suffix • Outfix                   -> <TODO: implement without new primitives> / <TODO: implement without new primitives>
# \: Grade Down • Sort                 -> <via generic sort> / <via generic sort>
#  
# [ Same • Left                        -> { -0 } / { -1 }
# [: Cap                               -> <nope>
# ] Same • Right                       -> { -0 } / { -0 }
# { Catalogue • From                   -> <TODO: should be implementable in terms of table> / { * }
# {. Head • Take                       -> <TODO: implement without new primitives> / <TODO: implement take interval without new primitives>
# {: Tail •                            -> <TODO: implement without new primitives>
# {:: Map • Fetch                      -> <nope>
# } Item Amend • Amend (m} u})         -> <TODO: implement without new primitives> / =[]
# }. Behead • Drop                     -> <TODO: implement without new primitives> / <TODO: implement without new primitives>
# }: Curtail •                         -> <TODO: implement without new primitives>
#  
# " Rank (m"n u"n m"v u"v)             -> <FIXME: think about (function) type casts>
# ". Do • Numbers                      -> <nope> / <FIXME: create (sscanf-style) parser>
# ": Default Format • Format           -> <FIXME: create (printf-style) printer>
# ` Tie (Gerund)                       -> <implement as arrays of functions>
# `: Evoke Gerund                      -> { _ len dearray -<logic> }
# @ Atop                               -> { -0*1* }
# @. Agenda                            -> { =i =fs { fs * * } i each }
# @: At                                -> <nope>
# & Bond / Compose                     -> <via various - constructs>
# &. &.: Under (Dual)                  -> <TODO: think about inverse functions>
# &: Appose                            -> <via various - constructs>
# ? Roll • Deal                        -> <TODO: implement rand>
# ?. Roll • Deal (fixed seed)          -> <TODO: implement srand>
#  
# a. Alphabet                          -> <TODO: maybe create a lib for this>
# a: Ace (Boxed Empty)                 -> <nope>
# A. Anagram Index • Anagram           -> <TODO: maybe create a lib for this>
# b. Boolean / Basic                   -> <TODO: implement generic boolean function> / <TODO: think about runtime token availability>
# C. Cycle-Direct • Permute            -> <TODO: maybe create a lib for this>
# d. Derivative                        -> <nope>
# D. Derivative                        -> <TODO: maybe create a lib for this (also consider run/compile-time token availablitiy)>
# D: Secant Slope                      -> <TODO: maybe create a lib for this (also consider run/compile-time token availablitiy)>
# e. Raze In • Member (In)             -> <nope> / <see grep.ey>
# E. • Member of Interval              -> <TODO: implement without new primitives>
# f. Fix                               -> <TODO: implement cloning of closures>
# H. Hypergeometric                    -> <TODO: maybe create a lib for this>
#  
# i. Integers • Index Of               -> range / <see grep.ey>
# i: Steps • Index Of Last             -> range <step> mul / <see grep.ey>
# I. Indices • Interval Index          -> <see grep.ey> / <nope>
# j. Imaginary • Complex               -> <TODO: complex>
# L. Level Of •                        -> <nope>
# L: Level At                          -> <nope>
# M. Memo                              -> <TODO: implement function result caching>
# NB. Comment                          -> #
# o. Pi Times • Circle Function        -> <TODO: create a lib for this>
# p. Roots • Polynomial                -> <TODO: create a lib for this>
# p.. Poly. Deriv. • Poly. Integral    -> <TODO: goes into the polynomial lib>
# p: Primes                            -> <TODO: create a lib for this>
#  
# q: Prime Factors • Prime Exponents   -> <TODO: goes into the primes lib>
# r. Angle • Polar                     -> <TODO: complex>
# s: Symbol                            -> <nope>
# S: Spread                            -> <nope>
# t. Taylor Coeff. (m t. u t.)         -> <TODO: goes into the polynomial lib>
# t: Weighted Taylor                   -> <TODO: goes into the polynomial lib>
# T. Taylor Approximation              -> <TODO: goes into the polynomial lib>
# u: Unicode                           -> <TODO: think about encoding>
# x: Extended Precision                -> <TODO: arbitrary precision lib>
# _9: to 9: Constant Functions         -> { 9 neg } ... { 9 }

use Time::HiRes qw(time);

my %timings;

sub takeTimings {
  my ($scope) = @_;

  foreach my $key (keys %$scope) {
    next if not ref($scope->{$key}->[1]);

    if($scope->{$key}->[1]->[0] eq 'func') {
      my $sub = $scope->{$key}->[0];
      my $name = $scope->{$key}->[1]->[1];

      $scope->{$key}->[0] = sub {
        my $start = time;
        &$sub(@_);
        $timings{$name} += time - $start;
      }
    } elsif($scope->{$key}->[1]->[0] eq 'struct') {
      takeTimings($scope->{$key}->[0]);
    }
  }
}

# takeTimings($global);

END {
  foreach my $key (sort { $timings{$a} <=> $timings{$b} } keys %timings) {
    printf "%s: %.6f\n", $key, $timings{$key};
  }
}

1;
