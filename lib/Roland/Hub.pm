#!/bin/env perl
package Roland::Hub;
use Moose;
use 5.12.0;

use Params::Util qw(_ARRAY _HASH);
use Roland::Result::Error;
use Roland::Result::Multi;
use Roland::Result::None;
use Roland::Result::Simple;
use Roland::Roller::Manual;
use Roland::Roller::Random;
use Roland::Table::Dictionary;
use Roland::Table::Group;
use Roland::Table::Monster;
use Roland::Table::Standard;
use YAML::XS ();

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

  my $data = eval {
    my @data = YAML::XS::LoadFile($fn);
    \@data;
  };
  my $error = $@ || "(unknown error)";

  unless ($data) {
    return Roland::Result::Error->new({
      resource => $fn,
      error    => $error,
    });
  }

  $self->roll_table( $data, $fn );
}

sub _type_and_rest {
  my ($self, $data) = @_;

  die "ill-formed document: @$data" if @$data > 1;

  return ($data->[0]{type} => $data->[0])
    if _HASH($data->[0]) && $data->[0]{type};

  return (table => $data->[0]) if _HASH($data->[0]);
  return (group => { items => $data->[0] }) if _ARRAY($data->[0]);

  Carp::croak("no idea what to do with table input: $data->[0]");
}

# Make this a registry -- rjbs, 2012-12-03
my %CLASS_FOR_TYPE = (
  monster => 'Roland::Table::Monster',
  group   => 'Roland::Table::Group',
  table   => 'Roland::Table::Standard',
  dict    => 'Roland::Table::Dictionary',
);

sub roll_table {
  my ($self, $input, $name) = @_;

  my ($type, $tables) = $self->_type_and_rest($input);

  if ($type eq 'file') {
    return $self->roll_table_file($tables);
  }

  if (my $class = $CLASS_FOR_TYPE{ $type }) {
    return $class->from_data($tables, $self)->roll_table;
  }

  die "wtf";
}

sub _result_for_line {
  my ($self, $payload, $table, $name) = @_;

  return Roland::Result::None->new unless defined $payload;

  return Roland::Result::Simple->new({ text => $payload }) unless ref $payload;

  if (_HASH($payload) && keys(%$payload) == 1) {
    my ($method, $arg) = %$payload;

    $method = 'roll_table' if $method eq 'table';
    $method = 'roll_table_file' if $method eq 'file';
    $method = 'resolve_multi' if $method eq 'times';
    return $self->$method($arg, $table);
  }

  return $self->roll_table([$payload]);
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

  my @results = map { $table->roll_table } (1 .. $num);
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

has roller => (
  is   => 'ro',
  isa  => 'Object', # Roland::Roller
  lazy => 1,
  handles => [ 'roll_dice' ],
  default => sub {
    $_[0]->manual ? Roland::Roller::Manual->new({ hub => $_[0] })
                  : Roland::Roller::Random->new({ hub => $_[0] })
  },
);

1;
