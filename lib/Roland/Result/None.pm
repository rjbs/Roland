package Roland::Result::None;
# ABSTRACT: no result!
use Moose;
with 'Roland::Result';

use namespace::autoclean;

sub as_text {
  my ($self, $indent) = @_;

  my $text = "(no result)";

  my $string = "$text\n";

  $string =~ s{^}
              {'  ' x ($indent // 0)}egm;

  return $string;
}

1;
