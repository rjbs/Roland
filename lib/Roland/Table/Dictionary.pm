package Roland::Table::Dictionary;
use Moose;
with 'Roland::Table';

use namespace::autoclean;

has _guts => (
  is => 'ro',
);

# - Label: table
# - Label: table
# - Label: table
# - Label: table

sub from_data {
  my ($class, $data, $hub) = @_;

  return $class->new({
    _guts => $data,
    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;

  my @slots = @{ $self->_guts->{entries} };

  my @results;
  for my $pair (@slots) {
    my $result = $self->hub->_result_for_line(
      $pair->[1],
      $self,
      "name:$pair->[0]", # should be our name
    );

    push @results, [ $pair->[0], $result ];
  }

  return Roland::Result::Dictionary->new({ results => \@results });
}

1;
