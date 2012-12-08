package Elymas;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  popInt popString popArray enstruct arrayAccess $quoted @globalCallStack
  interpretCode execute executeString executeFile resolve
);

use Data::Dumper;

our $quoted = 0;
our @globalCallStack;

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

sub enstruct {
  my ($struct) = @_;

  return ($struct, ['struct', { map { my @e = ($_, [@{$struct->{$_}}]); shift @{$e[1]}; @e } keys %$struct }]);
}

sub arrayAccess {
  my ($array, $data, $scope) = @_;

  my $i = pop @$data or die "Stack underflow";
  die "array index must be int" unless $i->[1] eq 'int';

  push @$data, $array->[0]->[$i->[0]];
}

sub interpretCode {
  my ($code, $data, $scope) = @_;

  foreach my $t (@$code) {
    eval {
      if($t->[1] eq 'tok') {
        die "unexpanded token in interpretCode";
      } elsif(ref($t->[1]) eq 'ARRAY' and $t->[1]->[0] eq 'func') {
        push @$data, $t;
        execute($data, $scope);
      } else {
        push @$data, $t;
      }
    };
    if($@) {
      #print "Code: " . Dumper($tokens);
      #print "Scope: " . Dumper($scope);
      print "Stack: " . Dumper($data);
      print "Token: " . Dumper($t);
      die;
    }
  }
}

sub typeStack {
  my ($type) = @_;

  if(ref($type) eq 'ARRAY') {
    if($type->[0] eq 'func' or $type->[0] eq 'array') {
      if(not exists $type->[2]) {
        die "type analysis incomplete on " . Dumper($type);
      }
      if(@{$type->[2]} == 1 and @{$type->[3]} == 1) {
        my $ret = typeStack($type->[3]->[0]);
        unshift @$ret, $type->[2]->[0];
        return $ret;
      }
    }
  }

  return [$type];
}

sub typeEqual {
  my ($a, $b) = @_;

  return 0 if(ref($a) xor ref($b));
  if(ref($a) and ref($b)) {
    return 0 if($a->[0] ne $b->[0]);

    if($a->[0] eq 'range') {
      return $a->[1] == $b->[1] && $a->[2] == $b->[2];
    } elsif($a->[0] eq 'array' or $a->[0] eq 'func') {
      return 0 if(@{$a->[2]} != @{$b->[2]});
      return 0 if(@{$a->[3]} != @{$b->[3]});

      return 0 unless @{$a->[2]} == grep { typeEqual($a->[2]->[$_], $b->[2]->[$_]) } 0 .. $#{$a->[2]};
      return 0 unless @{$a->[3]} == grep { typeEqual($a->[3]->[$_], $b->[3]->[$_]) } 0 .. $#{$a->[3]};
      return 1;
    } else {
      die "not yet implemented";
    }
  }

  return $a eq $b;
}

sub canCastTo {
  my ($subtype, $supertype) = @_;

  return 1 if(typeEqual($subtype, $supertype));
  return 1 if($supertype eq '*');
  return 1 if($supertype eq 'int' and ref($subtype) eq 'ARRAY' and $subtype->[0] eq 'range');

  return 0;
}

sub commonSubType {
  my ($a, $b) = @_;

  return $a if(canCastTo($a, $b));
  return $b if(canCastTo($b, $a));

  return undef;
}

sub typeMismatchCount {
  my ($formal, $concrete) = @_;

  my @rFormal = reverse @$formal;
  my @rConcrete = reverse @$concrete;

  my $mismatches = 0;

  while(@rFormal) {
    my $f = shift @rFormal;

    if(canCastTo($rConcrete[0], $f)) {
      shift @rConcrete;
    } else {
      ++$mismatches;
    }
  }

  return $mismatches;
}

sub isVariableType {
  my ($type) = @_;

  return 0;
}

sub isIterableType {
  my ($type) = @_;

  return 1 if(ref($type) eq 'ARRAY' and $type->[0] eq 'range');

  return 0;
}

sub getLoopStart {
  my ($iterable) = @_;

  if(ref($iterable->[1]) eq 'ARRAY' and $iterable->[1]->[0] eq 'array') {
    return [0, 'int'];
  }

  die "Cannot iterate: " . Dumper($iterable);
}

sub isLoopEnd {
  my ($iterable, $i) = @_;

  if(ref($iterable->[1]) eq 'ARRAY' and $iterable->[1]->[0] eq 'array') {
    return $i->[0] == @{$iterable->[0]};
  }

  die "Cannot iterate: " . Dumper($iterable);
}

sub doLoopStep {
  my ($iterable, $i) = @_;

  if(ref($iterable->[1]) eq 'ARRAY' and $iterable->[1]->[0] eq 'array') {
    return [$i->[0] + 1, 'int'];
  }

  die "Cannot iterate: " . Dumper($iterable);
}

# Executing a function f: A->B->C (i.e. B A f) on concrete arguments b a.
# Phase 1
#   Foreach argument:
#     Find the function input type from top of concrete argument type stack,
#       increase viewport from top of concrete type stack
#         match type from bottom to top, if type cannot be found, create constant function
#         final match is that which creates minimal number of constant function layers
# Phase 2
#   Foreach argument type:
#     Identify the type stack above the match from phase 1.
#     Run from right (stacktop) argument to left (stacklow) argument:
#       Take topmost type, check whether it can be found in other stacks (from top)
#         Eliminate all matching types via function or loop creation

sub execute {
  my ($data, $scope) = @_;
  my $f = pop @$data or die "Stack underflow";

  if(ref($f->[1]) ne 'ARRAY') {
    push @$data, $f;
    return;
  }

  if($f->[1]->[0] eq 'array') {
    my $ff = $f;
    $f = [sub {
      my ($data, $scope) = @_;
      arrayAccess($ff, $data, $scope);
    }, ['func', 'array-to-func-cast', ['int'], [$ff->[1]->[1]]]];
  }

  die "complex type unsuitable for execution" if($f->[1]->[0] ne 'func');

  if(not $f->[1]->[2]) {
    # untyped function, just call
    push @globalCallStack, $f;
    &{$f->[0]}($data, $scope);
    pop @globalCallStack;
    return;
  }

  my @concreteArgs;
  my @viewPortOffset;

  # Phase 1
  for(my $argI = $#{$f->[1]->[2]}; $argI >= 0; --$argI) {
    # print "Analyzing Arg $argI\n";

    my $formalArg = $f->[1]->[2]->[$argI];
    my $formalTypeStack = typeStack($formalArg);
    my $c = pop @$data;
    my $typeStack = typeStack($c->[1]);
    # die "Type-Stack: " . Dumper($typeStack);

    my $bestViewPortSize = 0;
    my $bestViewPortMatch = @$typeStack + 1;

    # print "Formal Type Stack: @$formalTypeStack\n";
    # print "       Type Stack: @$typeStack\n";

    if(isVariableType($typeStack->[-1])) {
      for(my $viewPortSize = 1; $viewPortSize < @$typeStack + 1; ++$viewPortSize) {
        my @typeViewPort;
        unshift @typeViewPort, $typeStack->[$_ - 1] for(1 .. $viewPortSize);

        # print "@$formalTypeStack vs. @$typeStack\n";

        my $viewPortMatch = typeMismatchCount($formalTypeStack, $typeStack);
        if($viewPortMatch < $bestViewPortMatch) {
          $bestViewPortSize = $viewPortSize;
          $bestViewPortMatch = $viewPortMatch;
        }
      }
    } else {
      $bestViewPortSize = @$typeStack;
      $bestViewPortMatch = 0;
    }

    # convert concrete argument to exactly matching function
    # ... which calls the concrete argument using its relevant args
    if($bestViewPortMatch == 0) {
      # zero mismatches, can directly use concrete argument
      unshift @viewPortOffset, @$typeStack - @$formalTypeStack;
    } else {
      # if argument is concrete, but we need are construction a function overall, then concrete
      # argument needs to be converted to a constant function in whatever domain is necessary
      die "concrete argument constant functionification needs to be implemented, mismatch: $bestViewPortMatch";
      $c = sub { "magic goes here FIXME" };
    }

    unshift @concreteArgs, $c;
  }

  # print "Viewport Offsets: @viewPortOffset\n";

  # Phase 2,
  my @toBeAbstractedTypes;
  foreach my $i (0 .. $#viewPortOffset) {
    my @remaining = @{typeStack($concreteArgs[$i]->[1])};
    @{$toBeAbstractedTypes[$i]} = @remaining[0 .. $viewPortOffset[$i] - 1];
  }

  # print "To be abstracted: " . Dumper(@toBeAbstractedTypes);

  if(not grep { @$_ } @toBeAbstractedTypes) {
    # no types need to be abstracted, function can be called
    push @globalCallStack, $f;
    &{$f->[0]}(\@concreteArgs, $scope);
    pop @globalCallStack;
    push @$data, @concreteArgs;
  } else {
    my @argTypes; # the type stack of the new function
    my @stageCalls; # which functions to call in each stage
    my @loops; # undef for lambda abstraction, loop bound source for loops

    foreach my $i (reverse 0 .. $#toBeAbstractedTypes) {
      while(@{$toBeAbstractedTypes[$i]}) {
        my $type = shift @{$toBeAbstractedTypes[$i]};

        my $stageCalls = [$i];
        my $iterationSource = undef; # which concrete argument we'll take the iteration bounds from
        if(isIterableType($type)) {
          $iterationSource = $i;
        }

        foreach my $j (reverse 0 .. $i - 1) {
          next unless @{$toBeAbstractedTypes[$j]};
          my $common = commonSubType($type, $toBeAbstractedTypes[$j]->[0]);
          next unless $common;
          $type = $common;

          if(isIterableType($type) and not defined $iterationSource) {
            $iterationSource = $j;
          }

          shift @{$toBeAbstractedTypes[$j]};
          unshift @$stageCalls, $j;
        }

        if(defined $iterationSource) {
          unshift @argTypes, undef;
          unshift @loops, $iterationSource;
        } else {
          unshift @argTypes, $type;
          unshift @loops, undef;
        }

        push @stageCalls, $stageCalls;
      }
    }

    # die Dumper(\@argTypes, \@stageCalls, \@loops);

    my $unravel; $unravel = sub {
      my ($data, $concreteArgs, $stageCalls, $argTypes, $loops) = @_;

      my @stageCallCopy = @$stageCalls;
      my @argTypeCopy = @$argTypes;
      my @loopCopy = @$loops;

      my $stage = pop @stageCallCopy;
      my $argType = pop @argTypeCopy;
      my $loop = pop @loopCopy;

      if($argType) {
        my $abstraction = sub {
          my ($data, $scope) = @_;
          my $v = pop @$data;

          my @argCopy = @$concreteArgs;

          foreach my $i (@$stage) {
            my @s = ($v, $argCopy[$i]);
            execute(\@s, $scope);
            $argCopy[$i] = $s[0];
          }

          &$unravel($data, \@argCopy, \@stageCallCopy, \@argTypeCopy, \@loopCopy);
        };

        push @$data, [$abstraction, ['func', 'autoabstraction of ' . $f->[1]->[1], [grep { $_ } @argTypeCopy], undef]];
        # FIXME the undef can be determined
      } elsif(defined $loop) {
        my @argCopy = @$concreteArgs;

        my @results;
        for (my $i = getLoopStart($argCopy[$loop]); !isLoopEnd($argCopy[$loop], $i); $i = doLoopStep($argCopy[$loop], $i)) {
          my @argCopy2 = @$concreteArgs;

          foreach my $j (@$stage) {
            my @s = ($i, $argCopy2[$j]);
            execute(\@s, $scope);
            $argCopy2[$j] = $s[0];
          }

          my $count = @$data;
          &$unravel($data, \@argCopy2, \@stageCallCopy, \@argTypeCopy, \@loopCopy);
          push @results, pop @$data;
          die "abstracted function produced multiple results (can be handled corretly, needs to be implemented)"
            unless $count == @$data;
          # by producing two arrays side by side
        }

        push @$data, [\@results, ['array', '[]', [['range', 0, $#results]], [undef]]];
        # FIXME the undef can be determined
      } else {
        my @argCopy = @$concreteArgs;

        push @globalCallStack, $f;
        &{$f->[0]}(\@argCopy, $scope);
        pop @globalCallStack;
        push @$data, @argCopy;
      }
    };

    &$unravel($data, \@concreteArgs, \@stageCalls, \@argTypes, \@loops);
  }
}

sub resolve {
  my ($scope, $data, $name) = @_;

  die "resolution for undefined name attempted" unless defined $name;

  return $scope->{$name} if(exists $scope->{$name});
  return resolve($scope->{' parent'}, $data, $name) if(exists $scope->{' parent'});

  if($name =~ /^(_+)(\d*)$/s) {
    my @spec = split //, $2;
    @spec = (0) unless @spec;

    return [sub {
      my ($data, $scope) = @_;

      my @new;
      foreach my $i (@spec) {
        die "Stack underflow" if @$data < $i + 1;
        push @new, $data->[-$i - 1];
      }
      push @$data, @new;
    }, ['func', 'auto-created of ' . $name], 'active'];
  } elsif($name =~ /^(-+)([0-9*]*)$/s) {
    my $max = length($1) - 1;
    my @spec = split //, $2;
    $max = $_ > $max? $_: $max foreach grep { $_ ne '*' } @spec;

    return [sub {
      my ($data, $scope) = @_;

      my @buffer;
      foreach (0 .. $max) {
        die "Stack underflow" unless @$data;
        push @buffer, pop @$data;
      }

      foreach my $i (@spec) {
        if($i eq '*') {
          execute($data, $scope);
        } else {
          push @$data, $buffer[$i];
        }
      }
    }, ['func', 'auto-created of ' . $name], 'active'];
  } elsif($name =~ /^\*(\d*)$/s) {
    my @spec = split //, $1;

    return [sub {
      my ($data, $scope) = @_;

      my @buffer;
      foreach my $i (@spec) {
        die "Stack underflow" if @$data < $i + 2;
        push @buffer, $data->[-$i - 2];
      }
      execute($data, $scope);
      push @$data, @buffer;
    }, ['func', 'auto-created of ' . $name], 'active'];
  }

  return undef;
}

sub applyResolvedName {
  my ($t, $meaning, $data, $scope) = @_;

  if(not defined $meaning) {
    if($quoted) {
      push @$data, [sub {
          my ($data, $scope) = @_;

          my $meaning = resolve($$scope, $data, $t->[0]);
          applyResolvedName($t, $meaning, $data, $scope);
        }, ['func', 'quoted late-resolve of ' . $t->[0]], $t->[0]];
    } else {
      die "could not resolve '$t->[0]'";
    }
  } elsif($meaning->[2] eq 'passive') {
    if($quoted) {
      push @$data, [sub { push @{$_[0]}, [$meaning->[0], $meaning->[1]] }, ['func', 'quoted-constant of ' . $t->[0]], $t->[0]];
    } else {
      push @$data, [$meaning->[0], $meaning->[1]];
    }
  } elsif($meaning->[2] eq 'active') {
    if($quoted) {
      push @$data, [$meaning->[0], $meaning->[1], $t->[0]];
    } else {
      push @$data, [$meaning->[0], $meaning->[1]];
      execute($data, $scope);
    }
  } elsif($meaning->[2] eq 'quote') {
    push @$data, [$meaning->[0], $meaning->[1]];
    execute($data, $scope);
  } else {
    die "unknown scope entry meaning for '$t->[0]'";
  }
}

sub interpretTokens {
  my ($tokens, $data, $scope) = @_;

  foreach my $t (@$tokens) {
    eval {
      if($t->[1] eq 'tok') {
        my $meaning = resolve($$scope, $data, $t->[0]);
        applyResolvedName($t, $meaning, $data, $scope);
      } elsif(ref($t->[1]) eq 'ARRAY' and $t->[1]->[0] eq 'func') {
        die "function pointer in interpretTokens";
      } else {
        push @$data, $t;
      }
    };
    if($@) {
      #print "Code: " . Dumper($tokens);
      #print "Scope: " . Dumper($scope);
      print "Stack: " . Dumper($data);
      print "Token: " . Dumper($t);
      die;
    }
  }
}

sub executeFile {
  my ($file, $data, $scope) = @_;

  open my $code, '<', $file or die "cannot open $file: $!";
  while(my $line = <$code>) {
    chomp $line;

    executeString($line, $data, $scope);
  }
  close $code;
}

sub executeString {
  my ($str, $data, $scope) = @_;

  my @tokens = tokenize($str);
  interpretTokens(\@tokens, $data, $scope);

  return $data;
}

sub tokenize {
  my ($line) = @_;
  $line .= ' ';

  my @t;

  while($line) {
    if($line =~ /^ +(.*)/s) {
      $line = $1;
    } elsif($line =~ /^#/s) {
      $line = '';
    } elsif($line =~ /^(\d+) +(.*)/s) {
      $line = $2;
      push @t, [$1, 'int'];
    } elsif($line =~ /^"([^"]+)" +(.*)/s) {
      $line = $2;
      push @t, [$1, 'string'];
    } elsif($line =~ /^([^a-zA-Z ]+)([a-zA-Z]+) +(.*)/s) {
      $line = "$1 $3";
      push @t, [$2, 'string'];
    } elsif($line =~ /^([a-zA-Z]+|[^a-zA-Z ]+) +(.*)/s) {
      $line = $2;
      push @t, [$1, 'tok'];
    } else {
      die "cannot tokenize: '$line'";
    }
  }

  return @t;
}

1;
