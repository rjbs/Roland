package Roland::Roller::Random;
# ABSTRACT: dice
use Moose;
with 'Roland::Roller';

use 5.12.0;

use Games::Dice ();
use List::AllUtils qw(shuffle sum);

use namespace::autoclean;

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  my @dice_str = split / \+ /, $dice;
  my $result = sum 0, map { Games::Dice::roll($_) } @dice_str;

  say "rolled $dice for $label: $result" if $self->debug;

  return $result;
}

sub pick_n {
  my ($self, $n, $max) = @_;

  Carp::cluck("picking $n from a $max size set") if $n > $max;

  my @shuffled_items = shuffle(0 .. $max);
  splice @shuffled_items, $n;
  return @shuffled_items;
}

1;
