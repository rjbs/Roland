package Roland::Roller;
use Moose::Role;

use namespace::autoclean;

requires 'roll_dice';
requires 'pick_n';

1;
