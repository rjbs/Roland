package Roland::Roller;
use Moose::Role;

use namespace::autoclean;

has hub => (
  is  => 'ro',
  isa => 'Object',
  required => 1,
  weak_ref => 1,
);

requires 'roll_dice';
requires 'pick_n';

1;
