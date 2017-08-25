package Roland::Table::Queue;

# ABSTRACT: a queue of results to get in order

use Moose;
with 'Roland::Table';

use namespace::autoclean;

use Roland::Result::Multi;

has items => (
  isa => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => {
    items_left => 'count',
    next_item  => 'shift',
    final_item => [ get => -1 ],
  },
  required => 1,
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  return $class->new({
    name  => $name,
    items => $data->{items},
    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;

  die "zero item queue!" if $self->items_left < 1;
  my $line = $self->items_left == 1 ? $self->final_item : $self->next_item;

  return $self->_result_for_line($line);
}

1;
