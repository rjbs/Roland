package Roland::Result::None;

# ABSTRACT: no result!

use Moose;
with 'Roland::Result';

use namespace::autoclean;

sub inline_text_is_lossy { 0 }

sub as_inline_text { '(no result)' }

sub as_block_text {
  my ($self, $indent) = @_;

  my $text = $self->as_inline_text;

  my $string = "$text\n";

  $string =~ s{^}
              {'  ' x ($indent // 0)}egm;

  return $string;
}

1;
