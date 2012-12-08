package Roland::Roller::Test;
# ABSTRACT: a roller pre-programmed with known results
use Moose;
with 'Roland::Roller';

# on_exhaustion attr with coderef or presets: fatal, rand, recycle
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

has _random_roller => (
  is   => 'ro',
  lazy => 1,
  default => sub { Roland::Roller::Random->new },
);

has random_fallback => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub next_roll {
  my ($self) = @_;
  my $next = $self->_next_roll;
  return $next if defined $next;
  return undef if $self->random_fallback;
  Carp::croak( "tried to get a roll when exhausted" );
}

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  return( $self->next_roll // $self->_random_roller->roll_dice($dice, $label) );
}

1;
