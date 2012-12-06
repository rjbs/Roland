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
use Roland::Table::List;
use Roland::Table::Monster;
use Roland::Table::Standard;
use YAML::XS ();

sub roll_table_file {
  my ($self, $fn, @rest) = @_;

  unless ($fn) {
    return Roland::Result::Error->new({
      resource => '?',
      error    => "no filename given"
    });
  }

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

  unless (@$data) {
    return Roland::Result::Error->new({
      resource => $fn,
      error    => "file contained no documents",
    });
  }

  warn "ignoring documents after the first in $fn" if @$data > 1;

  $self->build_and_roll_table( $fn, $data->[0], @rest );
}

sub _type_and_rest {
  my ($self, $data) = @_;

  return ($data->{type} => $data)
    if _HASH($data) && $data->{type};

  return (table => $data) if _HASH($data);
  return (list  => { items => $data }) if _ARRAY($data);

  Carp::croak("no idea what to do with table input: $data");
}

# Make this a registry -- rjbs, 2012-12-03
my %CLASS_FOR_TYPE = (
  monster => 'Roland::Table::Monster',
  list    => 'Roland::Table::List',
  table   => 'Roland::Table::Standard',
  dict    => 'Roland::Table::Dictionary',
);

sub build_and_roll_table {
  my ($self, $name, $data, @rest) = @_;

  my ($type, $table) = $self->_type_and_rest($data);

  if (my $class = $CLASS_FOR_TYPE{ $type }) {
    return $class->from_data($name, $table, $self)->roll_table(@rest);
  }

  Roland::Result::Error->new({
    resource => $name || "table",
    error    => "don't know how to handle table of type $type",
  });
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
