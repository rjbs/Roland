package Roland::Roller::Manual;

# ABSTRACT: let the DM roll and tell Roland what came up

use Moose;
with 'Roland::Roller';

use namespace::autoclean;

use List::AllUtils qw(sum);

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  my $result;
  local $| = 1;
  my $default = do {
    Games::Dice::roll($dice);
    my @dice_str = split / \+ /, $dice;
    sum 0, map { Games::Dice::roll($_) } @dice_str;
  };
  $dice .= " for $label" if $label;
  print "rolling $dice [$default]: ";
  $result = <STDIN>;
  chomp $result;
  $result = $default unless length $result;

  return $result;
}

sub pick_n {
  my ($self, $n, $max) = @_;
  my @default = Roland::Roller::Random->new->pick_n($n, $max);
  local $| = 1;
  print "enter $n integer(s) in (0..$max) [@default]: ";
  my $result = <STDIN>;
  chomp $result;
  return @default unless $result =~ /\S/;
  split /\s+/, $result;
}

1;
