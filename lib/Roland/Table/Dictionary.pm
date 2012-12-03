package Roland::Table::Dictionary;
use Moose;
with 'Roland::Table';

use namespace::autoclean;

use Roland::Result::Dictionary;

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
    warn "too many / not enough keys" unless 1 == (my ($key) = keys %$pair);

    my $result = $self->hub->_result_for_line(
      $pair->{$key},
      $self,
      "name:$pair->{$key}", # should be our name
    );

    push @results, [ $key, $result ];
  }

  return Roland::Result::Dictionary->new({ results => \@results });
}

1;
