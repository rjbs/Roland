package Roland::Table;
# ABSTRACT: a table; you roll on it
use Moose::Role;
use 5.12.0;

use namespace::autoclean;

use Params::Util qw(_ARRAY0 _HASH);
use Roland::Result::Multi;

has hub => (
  is  => 'ro',
  isa => 'Object',
  required => 1,
  weak_ref => 1,
  handles  => [ qw(
    roll_dice
    build_and_roll_table
  ) ],
);

has name => (
  is  => 'ro',
  isa => 'Str',
  builder => '_build_name',
);

sub _build_name {
  my ($self) = @_;
  state $i = 1;
  sprintf '%s<%s>', (ref $self), $i++;
}

sub roll_multi {
  my ($self, $times) = @_;

  my $num = $self->roll_dice(
    $times,
    "times to roll on " . $self->name
  );

  my @results = map { $self->roll_table } (1 .. $num);
  return Roland::Result::Multi->new({ results => \@results });
}

sub replace {
  my ($self, $arg) = @_;
  require Roland::Redirect::Replace;
  die Roland::Redirect::Replace->new({
    result => $self->_result_for_line($arg),
  });
}

sub append {
  my ($self, $arg) = @_;
  require Roland::Redirect::Append;
  die Roland::Redirect::Append->new({
    result => $self->_result_for_line($arg),
  });
}

my %CMD_METHOD = (
  file    => sub {
    my ($table, $file, @rest) = @_;
    $table->hub->load_table_file($file)->roll_table(@rest);
  },
  times   => 'roll_multi',
  replace => 'replace',
  append  => 'append',
);

sub method_for_instruction {
  my ($self, $instruction) = @_;
  return $CMD_METHOD{ $instruction };
}

sub subtable_name {
  my ($self, $key) = @_;
  return $self->name . q{, } . ($key // "?");
}

sub _result_for_line {
  my ($self, $payload, $name, $arg) = @_;

  my $line_name = $self->subtable_name($name);

  return Roland::Result::None->new unless defined $payload;

  return Roland::Result::Simple->new({ text => $payload }) if ! ref $payload;

  if (_HASH($payload) && keys(%$payload) == 1) {
    my ($instruction, @args) = %$payload;
    @args = @{ $args[0] } if _ARRAY0($args[0]);

    my $method = $self->method_for_instruction($instruction) || sub {
      Roland::Result::Error->new({
        resource => $line_name,
        error    => "encountered unknown instruction: $instruction",
      });
    };

    return $self->$method(@args);
  }

  return $self->build_and_roll_table($line_name, $payload, $arg);
}

requires 'roll_table';

1;
