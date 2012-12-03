#!/bin/env perl
package Roland::Hub;
use Moose;
use 5.12.0;

use Games::Dice;
use List::AllUtils qw(sum);
use Params::Util qw(_ARRAY _HASH);
use Roland::Result::Error;
use Roland::Result::Multi;
use Roland::Result::None;
use Roland::Result::Simple;
use Roland::Table::Group;
use Roland::Table::Monster;
use Roland::Table::Standard;
use YAML::Tiny;

sub resolve_table {
  my ($self, $table) = @_;

  $self->roll_table_file($table);
}

sub roll_table_file {
  my ($self, $fn) = @_;

  unless (-e $fn) {
    return Roland::Result::Error->new({
      resource => $fn,
      error    => "file not found"
    });
  }

  my $data = YAML::Tiny->read($fn);

  unless ($data) {
    return Roland::Result::Error->new({
      resource => $fn,
      error    => $YAML::Tiny::errstr,
    });
  }

  $self->roll_table( $data, $fn );
}

sub _header_and_rest {
  my ($self, $data) = @_;

  if (! ref $data->[0]) {
    return (
      { type => $data->[0] },
      [ @$data[ 1 .. $#$data ] ],
    )
  }

  die "ill-formed document" if @$data > 1;

  return ({ type => 'table' } => $data->[0]) if _HASH($data->[0]);
  return ({ type => 'group' } => { items => $data->[0] }) if _ARRAY($data->[0]);

  Carp::croak("no idea what to do with table input: $data->[0]");
}

# Make this a registry -- rjbs, 2012-12-03
my %CLASS_FOR_TYPE = (
  monster => 'Roland::Table::Monster',
  group   => 'Roland::Table::Group',
  table   => 'Roland::Table::Standard',
);

sub roll_table {
  my ($self, $input, $name) = @_;

  my ($header, $tables) = $self->_header_and_rest($input);

  if (my $class = $CLASS_FOR_TYPE{ $header->{type} }) {
    return $class->from_data($tables, $self)->roll_table;
  }

  die "wtf";
}

sub _result_for_line {
  my ($self, $payload, $data, $name) = @_;

  return Roland::Result::None->new unless defined $payload;

  if (ref $payload) {
    # Almost certainly this blind "wrap it in a []" needs to be revised later,
    # but for now it should work just fine. -- rjbs, 2012-11-30
    return $self->roll_table([$payload], "$name/sub");
  }

  my ($type, $rest) = split /\s+/, $payload, 2;

  my $method = $type eq 'T' ? 'resolve_table'
             : $type eq 'x' ? 'resolve_multi'
             # : $type eq 'G' ? 'resolve_goto'
             : $type eq '=' ? '_resolve_simple'
             :                undef;

  unless ($method) {
    return Roland::Result::Error->new({
      resource => "instruction <$payload>",
      error    => "don't know how to dispatch",
    });
  }

  my $result = $self->$method($rest, $data, $name);
}

sub _resolve_simple {
  Roland::Result::Simple->new({ text => $_[1] })
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

  my $num = $self->roll_dice($x, "times to roll on $name");

  my @results = map { $self->roll_table($table, $name) } (1 .. $num);
  return Roland::Result::Multi->new({ results => \@results });
}

has debug => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

has manual => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

# TODO delegate this to a Roller
sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

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
    say "rolled $dice for $label: $result" if $self->debug;
    return $result;
  }

  return $result;
}

1;
