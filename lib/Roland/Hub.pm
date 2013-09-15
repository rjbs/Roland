#!/bin/env perl
package Roland::Hub;
# ABSTRACT: the hub of rolly activity
use Moose;
use 5.12.0;

use Params::Util qw(_ARRAY _HASH);
use Roland::Result::Error;
use Roland::Result::Multi;
use Roland::Result::None;
use Roland::Result::Simple;
use Roland::Roller::Manual;
use Roland::Roller::Random;
use Roland::Table::Constant;
use Roland::Table::Dictionary;
use Roland::Table::List;
use Roland::Table::Lookup;
use Roland::Table::Queue;
use Roland::Table::Monster;
use Roland::Table::Standard;
use YAML::XS ();

sub __error_table {
  my ($self, $res, $error) = @_;

  return Roland::Table::Constant->new({
    hub    => $self,
    result => Roland::Result::Error->new({
      resource => $res,
      error    => $error,
    }),
  });
}

sub load_table_file {
  my ($self, $fn) = @_;

  return $self->__error_table('?', "no filename given") unless $fn;
  return $self->__error_table($fn, "file not found")    unless -e$fn;

  my $data = eval {
    my @data = YAML::XS::LoadFile($fn);
    \@data;
  };
  my $error = $@ || "(unknown error)";

  return $self->__error_table($fn, $error) unless $data;
  return $self->__error_table($fn, "file contained no documents") unless @$data;

  warn "ignoring documents after the first in $fn" if @$data > 1;

  $self->build_table($fn, $data->[0]);
}

sub _type_and_rest {
  my ($self, $data) = @_;

  return ($data->{type} => $data)
    if _HASH($data) && $data->{type};

  return (table => $data) if _HASH($data);
  return (list  => { items => $data }) if _ARRAY($data);

  return;
}

has type_registry => (
  isa     => 'HashRef',
  traits  => [ 'Hash' ],
  builder => 'build_type_registry',
  handles => { class_for_type => 'get' },
);

sub build_type_registry {
  return {
    dict    => 'Roland::Table::Dictionary',
    list    => 'Roland::Table::List',
    lookup  => 'Roland::Table::Lookup',
    queue   => 'Roland::Table::Queue',
    monster => 'Roland::Table::Monster',
    table   => 'Roland::Table::Standard',
  }
}

sub build_table {
  my ($self, $name, $data) = @_;

  return $self->__error_table($name => "no idea what to do with input $data")
    unless my ($type, $table) = $self->_type_and_rest($data);

  if (my $class = $self->class_for_type($type)) {
    return $class->from_data($name, $table, $self);
  }

  $self->__error_table(
    $name || 'table',
    "don't know how to handle table of type $type",
  );
}

sub build_and_roll_table {
  my ($self, $name, $data, @rest) = @_;

  $self->build_table($name, $data)->roll_table(@rest);
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
    $_[0]->manual ? Roland::Roller::Manual->new({ debug => $_[0]->debug })
                  : Roland::Roller::Random->new({ debug => $_[0]->debug })
  },
);

1;
