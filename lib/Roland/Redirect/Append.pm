package Roland::Redirect::Append;
# ABSTRACT: a result that says "add this on, too"
use Moose;
use namespace::autoclean;

has result => (is => 'ro');

sub actual_result {
  my ($self) = @_;
  my $result = $self;
  $result = $result->result until $result->does('Roland::Result');
  return $result;
}

sub as_text {
  my ($self) = @_;
  return "REPLACE CONTAINER WITH:\n" . $self->actual_result->as_text;
}

1;
