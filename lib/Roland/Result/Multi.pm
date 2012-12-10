package Roland::Result::Multi;
# ABSTRACT: a bunch of results
use Moose;
with 'Roland::Result';

use namespace::autoclean;

use List::AllUtils qw(any);

has results => (
  isa => 'ArrayRef',
  required => 1,
  traits   => [ 'Array' ],
  handles  => { results => 'elements' },
);

sub inline_text_is_lossy {
  return any { $_->inline_text_is_lossy } $_[0]->results;
}

sub as_inline_text {
  my ($self) = @_;
  join q{, }, map {; $_->as_inline_text } $self->results;
}

sub as_block_text {
  my ($self, $indent) = @_;
  $indent //= 0;

  my @hunks;
  for my $result ($self->results) {
    push @hunks, $result->as_block_text(
      $result->isa('Roland::Result::Multi') ? $indent+1 : $indent
    );
  }

  return join qq{\n}, @hunks;
}

1;
