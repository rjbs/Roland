package Roland::Table::List;

# ABSTRACT: a table listing unweighted results

use Moose;
with 'Roland::Table';

use namespace::autoclean;

use Roland::Result::Multi;

has pick_count => (
  is  => 'ro',
  isa => 'Int', # > 0 -- rjbs, 2012-12-09
  predicate => 'has_pick_count',
);

has items => (
  isa => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => { items => 'elements' },
  required => 1,
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  return $class->new({
    name  => $name,
    items => $data->{items},
    hub   => $hub,
    (defined $data->{pick} ? (pick_count => $data->{pick}) : ()),
  });
}

sub roll_table {
  my ($self) = @_;

  my @list = $self->items;

  my @keys = (0 .. $#list);

  if ($self->has_pick_count) {
    @keys = $self->hub->roller->pick_n($self->pick_count, $#list);
  }

  my @group;
  for my $i (@keys) {
    my $result = $self->_result_for_line(
      $list[$i],
      "item $i",
    );

    push @group, $result unless $result->isa('Roland::Result::None');
  }

  return Roland::Result::None->new unless @group;
  return $group[0] if @group == 1;
  return Roland::Result::Multi->new({ results => \@group });
}

1;
