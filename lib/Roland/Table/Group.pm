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
    # This is not determinable right now.  This should be fixed.  The question
    # is: how?  Do we want to add a ->pick_n_randomly(@list) to Roller?  Do we
    # want to roll dice over and over to pick?  Remember that this solution
    # avoided any stupid "I had to roll 10,000 times" or "I couldn't pick as
    # many as were requested," so do not introduce those bugs with the later
    # version. -- rjbs, 2012-12-05
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
