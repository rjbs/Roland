package Roland::Result::Simple;

# ABSTRACT: a result that's just a string

use Moose;
with 'Roland::Result';

use namespace::autoclean;

has text => (is => 'ro');

sub inline_text_is_lossy { 0 }

sub as_inline_text {
  $_[0]->text;
}

sub as_block_text {
  my ($self, $indent) = @_;

  my $text = $self->text;

  my $string = "$text";

  $string =~ s{^}
              {'  ' x ($indent // 0)}egm;

  return $string;
}

1;
