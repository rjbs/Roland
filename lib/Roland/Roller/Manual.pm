package Roland::Roller::Manual;
use Moose;
with 'Roland::Roller';

sub roll_dice {
  my ($self, $dice, $label) = @_;

  return $dice if $dice !~ /d/;

  my $result;
  local $| = 1;
  my $default = Games::Dice::roll($dice);
  $dice .= " for $label" if $label;
  print "rolling $dice [$default]: ";
  $result = <STDIN>;
  chomp $result;
  $result = $default unless length $result;

  return $result;
}

1;
