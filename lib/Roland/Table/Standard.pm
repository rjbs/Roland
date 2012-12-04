package Roland::Table::Standard;
use Moose;
with 'Roland::Table';

use List::AllUtils qw(sum);
use Roland::Result::Multi;

use namespace::autoclean;

has _guts => (
  is => 'ro',
);

sub from_data {
  my ($class, $table, $hub) = @_;

  return $class->new({
    _guts => $table,
    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;
  my $name //= "?";
  my $table = $self->_guts;
  my @dice_str = split / \+ /, $table->{dice};

  my @results;
  for my $i (
    1 .. $self->hub->roll_dice($table->{times} // 1, "times to roll on $name")
  ) {
    my %results = %{ $table->{results} };

    my $total = sum 0, map { $self->hub->roll_dice($_, $name) } @dice_str;

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

    my $result = $self->_result_for_line($payload);
    push @results, $result unless $result->isa('Roland::Result::None');
  }

  # must return a Result object
  return Roland::Result::None->new unless @results;
  return $results[0] if @results == 1;
  return Roland::Result::Multi->new({ results => \@results });
}

1;
