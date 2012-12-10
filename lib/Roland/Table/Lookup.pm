package Roland::Table::Lookup;
use Moose;

with 'Roland::Table';

use namespace::autoclean;

has default => (
  is  => 'ro',
  isa => 'Str',
);

has lookup => (
  isa    => 'HashRef',
  traits => [ 'Hash' ],
  required => 1,
  handles  => {
    lookup_keys => 'keys',
    result_for  => 'get',
  },
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  $class->new({
    name => $name,
    hub  => $hub,

    lookup  => $data->{lookup},
    (exists $data->{default} ? (default => $data->{default}) : ()),
  });
}

sub roll_table {
  my ($self, $key) = @_;

  $key = $key->as_inline_text
    if bless $key and $key->does('Roland::Result');

  unless (defined $key) {
    my @keys = $self->lookup_keys;
    my ($i) = $self->hub->roller->pick_n(1, $#keys);
    $key = $keys[$i];
  }

  return $self->_result_for_line( $self->result_for($key) , $key);
}

1;
