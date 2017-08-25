package Roland::Table::Standard;

# ABSTACT: a table where you roll dice and look up a result

use Moose;
with 'Roland::Table';

use List::AllUtils qw(sum);
use Roland::Result::Multi;

use namespace::autoclean;

has times => (
  is => 'ro',
);

has dice => (
  is => 'ro',
);

has results => ( # XXX: bad name -- rjbs, 2012-12-09
  is => 'ro',
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  return $class->new({
    name  => $name,

    times   => $data->{times} // 1,
    dice    => $data->{dice},
    results => $data->{results}, # rename?

    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;
  my $name = $self->name;

  my @results;
  for my $i (
    1 .. $self->hub->roll_dice($self->times // 1, "times to roll on $name")
  ) {
    my %results = %{ $self->results };

    my $total = $self->hub->roll_dice($self->dice, $name);

    my %case;
    for my $key (keys %results) {
      if ($key =~ /-/) {
        my ($min, $max) = split /-/, $key;
        $case{ $_ } = $results{$key} for $min .. $max;
      } else {
        $case{ $key } = $results{$key};
      }
    }

    my $payload = $case{ $total };

    my $result = $self->_result_for_line($payload, "result $total");
    push @results, $result unless $result->isa('Roland::Result::None');
  }

  # must return a Result object
  return Roland::Result::None->new unless @results;
  return $results[0] if @results == 1;
  return Roland::Result::Multi->new({ results => \@results });
}

1;
