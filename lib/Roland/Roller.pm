package Roland::Roller;
use Moose::Role;

use namespace::autoclean;

has debug => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

requires 'roll_dice';
requires 'pick_n';

1;
