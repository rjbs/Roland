package Roland::Result::Simple;
use Moose;
with 'Roland::Result';

use namespace::autoclean;

has text => (is => 'ro');

sub as_text {
  my ($self, $indent) = @_;

  my $text = $self->text;

  my $string = "$text";

  $string =~ s{^}
              {'  ' x ($indent // 0)}egm;

  return $string;
}

1;
