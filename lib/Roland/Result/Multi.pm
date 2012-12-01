package Roland::Result::Multi;
use Moose;
with 'Roland::Result';

use namespace::autoclean;

has results => (
  isa => 'ArrayRef',
  required => 1,
  traits   => [ 'Array' ],
  handles  => { results => 'elements' },
);

sub as_text {
  my ($self, $indent) = @_;

  return join qq{\n}, map {; $_->as_text($indent) } $self->results;
}

1;
