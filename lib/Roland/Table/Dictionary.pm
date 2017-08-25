package Roland::Table::Dictionary;

# ABSTRACT: a table of ordered name/value pairs

use Moose;
with 'Roland::Table';

use 5.16.0;

use namespace::autoclean;

use Roland::Result::Dictionary;
use Sort::ByExample;

has _things => (
  isa     => 'HashRef',
  traits  => [ 'Hash' ],
  handles => {
    _thing_for => 'get',
    unordered_keys => 'keys',
  },
);

has key_order => (
  isa     => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => {
    key_order => 'elements',
  },
  predicate => 'has_key_order',
);

sub _args_from_data {
  my ($class, $name, $data, $hub) = @_;

  my @slots = @{ $data->{entries} };

  my @order;
  my %dict;

  for my $pair (@slots) {
    warn "too many / not enough keys" unless 1 == (my ($key) = keys %$pair);

    warn "duplicate dictionary entry for $key" if $dict{$key};
    $dict{$key} = $pair->{$key};
    push @order, $key;
  }

  return {
    name  => $name,
    hub   => $hub,
    key_order => \@order,
    _things   => \%dict,
  };
}

# XXX: C&P between here and Result::Dict -- rjbs, 2012-12-11
has ordered_keys => (
  isa     => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => {
    ordered_keys => 'elements',
  },
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    my ($self) = @_;
    return [ $self->unordered_keys ] unless $self->has_key_order;

    my @results = Sort::ByExample->sorter(
      [ $self->key_order ],
      sub { fc $_[0] cmp fc $_[1] },
    )->($self->unordered_keys);

    return \@results;
  },
);

sub from_data {
  my ($class, @rest) = @_;
  my $args = $class->_args_from_data(@rest);
  return $class->new($args);
}

sub roll_table {
  my ($self) = @_;

  my %result_for;
  for my $key ($self->ordered_keys) {
    my $line = $self->_thing_for($key);

    $result_for{$key} = $self->_result_for_line($line, $key);
  }

  return Roland::Result::Dictionary->new({
    ($self->has_key_order ? (key_order => [ $self->key_order ]) : ()),
    results   => \%result_for,
  });
}

1;
