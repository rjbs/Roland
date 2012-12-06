package Roland::Roller::Test;
use Moose;
with 'Roland::Roller';

has planned_rolls => (
  isa => 'ArrayRef[Int]',
  traits  => [ 'Array' ],
  default => sub {  []  },
  handles => {
    _next_roll  => 'shift',
    clear_rolls => 'clear',
    push_rolls  => 'push',
    rolls_exhausted => 'is_empty',
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

sub next_roll {
  my ($self) = @_;
  my $next = $self->_next_roll;
  return $next if defined $next;
  Carp::croak( "tried to get a roll when exhausted" );
}

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  return $self->next_roll;
}

1;
