package Roland::Result::Error;
# ABSTRACT: something went wrong
use Moose;
with 'Roland::Result';

use namespace::autoclean;

has resource => (is => 'ro', isa => 'Str', required => 1);
has error    => (is => 'ro', isa => 'Str', required => 1);

sub as_text {
  my ($self, $indent) = @_;

  my $text = $self->error;

  my $string = "error with " . $self->resource . "\n"
             . $self->error . "\n";

  $string =~ s{^}
              {'  ' x ($indent // 0)}egm;

  return $string;
}

1;
