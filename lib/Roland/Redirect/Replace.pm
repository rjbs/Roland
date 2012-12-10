package Roland::Redirect::Replace;
# ABSTRACT: a result that says "replace the enclosing result"
use Moose;
use namespace::autoclean;

has result => (is => 'ro');

sub actual_result {
  my ($self) = @_;
  my $result = $self;
  $result = $result->result until $result->does('Roland::Result');
  return $result;
}

1;
