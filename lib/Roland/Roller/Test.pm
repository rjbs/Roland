package Roland::Roller::Test;
use Moose;
with 'Roland::Roller';

has planned_results => (
  isa => 'ArrayRef[Int]',
  traits  => [ 'Array' ],
  default => sub {  []  },
  handles => {
    _next_result  => 'shift',
    clear_results => 'clear',
    push_results  => 'push',
  },
);

sub pick_n;
has pick_n => (
  isa    => 'CodeRef',
  traits => [ 'Code' ],
  required => 1,
  handles  => {
    pick_n => 'execute_method',
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
