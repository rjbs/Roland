package Roland::Table::Group;
use Moose;
with 'Roland::Table';

use namespace::autoclean;

use List::AllUtils 'shuffle';
use Roland::Result::Multi;

has _guts => (
  is => 'ro',
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  return $class->new({
    name  => $name,
    _guts => $data,
    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;

  my @list = @{ $self->_guts->{items} };

  my @keys = (0 .. $#list);

  if ($self->_guts->{pick}) {
    my @shuffled_keys = shuffle @keys;
    splice @shuffled_keys, $self->_guts->{pick};
    @keys = sort { $a <=> $b } @shuffled_keys;
  }

  my @group;
  for my $i (@keys) {
    my $result = $self->_result_for_line(
      $list[$i],
      "item $i",
    );

    push @group, $result unless $result->isa('Roland::Result::None');
  }

  return Roland::Result::Multi->new({ results => \@group });
}

1;
