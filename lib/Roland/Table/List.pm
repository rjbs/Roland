package Roland::Table::List;
use Moose;
with 'Roland::Table';

use namespace::autoclean;

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

  if (defined $self->_guts->{pick}) {
    @keys = $self->hub->roller->pick_n($self->_guts->{pick}, \@keys);
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
