#!/bin/env perl
package Roland::Hub;
use Moose;
use 5.12.0;

use Games::Dice;
use List::AllUtils qw(sum);
use Roland::Result::Monster;
use Roland::Result::Multi;
use Roland::Result::Simple;
use YAML::Tiny;

sub resolve_table {
  my ($self, $table) = @_;

  $self->roll_table_file($table);
}

sub roll_table_file {
  my ($self, $fn) = @_;

  unless (-e $fn) {
    return Roland::Result::Simple->new({
      text => "(missing file, $fn)"
    });
  }

  my $data = YAML::Tiny->read($fn);
  die "error in $fn: $YAML::Tiny::errstr" unless $data;
  $self->roll_table( $data, $fn );
}

sub roll_table {
  my ($self, $data, $name) = @_;
  my $table = $data->[0];

  if ($table->{type} // 'list' eq 'monster') {
    return Roland::Result::Monster->from_data($data, $self);
  }

  die "multiple documents in standard table" if @$data > 1;

  $name //= "?";
  my @dice_str = split / \+ /, $table->{dice};

  my $total = sum 0, map { $self->roll_dice($_, $name) } @dice_str;

  my %case;
  for my $key (keys %{ $table->{results} }) {
    if ($key =~ /-/) {
      my ($min, $max) = split /-/, $key;
      $case{ $_ } = $table->{results}{$key} for $min .. $max;
    } else {
      $case{ $key } = $table->{results}{$key};
    }
  }

  my $payload = $case{ $total };

  # XXX: Is this really how you want to handle an undef entry?
  # -- rjbs, 2012-11-30
  return Roland::Result::Simple->new({ text => "(no result)" })
    unless defined $payload;

  my ($type, $rest) = split /\s+/, $payload, 2;

  my $method = $type eq 'T' ? 'resolve_table'
             : $type eq 'x' ? 'resolve_multi'
             # : $type eq 'G' ? 'resolve_goto'
             : $type eq '=' ? '_resolve_simple'
             :                sub { $_[1] };

  my $result = $self->$method($rest, $data, $name);

  # must return a Result object
  return $result;
}

sub _resolve_simple {
  Roland::Result::Simple->new({ text => $_[1] })
}

sub _resolve_monster {
  my ($self, $path) = @_;

  my $fn = "monster/$path";
  unless (-e $fn) {
    return Roland::Result::Simple->new({
      text => "(missing file, $fn)"
    });
  }

  my $data = YAML::Tiny->read($fn);
  die "error in $fn: $YAML::Tiny::errstr" unless $data;
  $data->[0]->{type} = 'monster';
  $self->roll_table( $data, $fn );
  # Roland::Result::Monster->from_file($path, $self);
}

#sub resolve_goto {
#  my ($self, $string, $table, $name) = @_;
#
#  my ($method, $arg) = $self->_plan_for_string($string);
#  my $text = $self->$method($arg, $table, $name);
#}

sub resolve_multi {
  my ($self, $x, $table, $name) = @_;
  # XXX: no, this should get a list of [ $table, $name ] tuples to combine or
  # something -- rjbs, 2012-11-27

  my @results = map { $self->roll_table($table, $name) } (1 .. $x);
  return Roland::Result::Multi->new({ results => \@results });
}

has manual => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub roll_dice {
  my ($self, $dice, $label) = @_;

  my $result;

  if ($self->manual) {
    local $| = 1;
    my $default = Games::Dice::roll($dice);
    $dice .= " for $label" if $label;
    print "rolling $dice [$default]: ";
    my $result = <STDIN>;
    chomp $result;
    $result = $default unless length $result;
    return $result;
  } else {
    my $result = Games::Dice::roll($dice);
    print "rolled $dice for $label: $result\n";
    return $result;
  }

  return $result;
}

1;
