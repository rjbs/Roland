package Roland::Roller::Test;
use Moose;
with 'Roland::Roller';

has planned_results => (
  isa => 'ArrayRef[Int]',
  traits  => 'Array',
  default => sub {  []  },
  handles => {
    _next_result  => 'shift',
    clear_results => 'empty',
    push_results  => 'push',
  },
);

sub next_result {
  my ($self) = @_;
  my $next = $self->_next_result;
  return $next if defined $next;
  Carp::croak( "tried to get a result when exhausted" );
}

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  return $self->next_result;
}

1;
