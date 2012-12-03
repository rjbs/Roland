package Roland::Table;
use Moose::Role;

use namespace::autoclean;

has hub => (
  is  => 'ro',
  isa => 'Object',
  required => 1,
  weak_ref => 1,
);

1;
