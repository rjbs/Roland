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
  my ($class, $tables, $hub) = @_;

  die "multiple documents in standard table" if @$tables > 1;
  my $table = $tables->[0];

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
    my $total = sum 0, map { $self->hub->roll_dice($_, $name) } @dice_str;

    my %case;
    for my $key (keys %{ $table->{results} }) {
      if ($key =~ /-/) {
        my ($min, $max) = split /-/, $key;
        $case{ $_ } = $table->{results}{$key} for $min .. $max;
      } else {
        $case{ $key } = $table->{results}{$key};
      }
    }

    my $payload = $case{ $total };

    my $result = $self->hub->_result_for_line($payload, [$table], $name);
    push @results, $result unless $result->isa('Roland::Result::None');
  }

  # must return a Result object
  return Roland::Result::None->new unless @results;
  return $results[0] if @results == 1;
  return Roland::Result::Multi->new({ results => \@results });
}

1;
