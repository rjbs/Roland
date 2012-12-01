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

  my @hunks;
  for my $result ($self->results) {
    push @hunks, $result->as_text(
      $result->isa('Roland::Result::Multi') ? $indent+1 : $indent
    );
  }

  return join qq{\n}, @hunks;
}

1;
