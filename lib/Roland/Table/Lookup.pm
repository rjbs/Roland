package Roland::Table::Lookup;
use Moose;

with 'Roland::Table';

use namespace::autoclean;

has key => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

has default => (
  is  => 'ro',
  isa => 'Str',
  predicate => 'has_default',
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

    key     => $data->{key},
    lookup  => $data->{lookup},
    (exists $data->{default} ? (default => $data->{default}) : ()),
  });
}

sub roll_table {
  my ($self, $input) = @_;
  $input //= {};

  my $key = $input->{ $self->key };

  $key = $key->as_inline_text
    if blessed $key and $key->does('Roland::Result');

  unless (defined $key) {
    if ($self->has_default) {
      $key = $self->default;
    } else {
      # my @keys = $self->lookup_keys;
      # my ($i) = $self->hub->roller->pick_n(1, $#keys);
      # $key = $keys[$i];
      return Roland::Result::Error->new({
        resource => "lookup table " . $self->name,
        error    => "couldn't determine key to look up",
      });
    }
  }

  return $self->_result_for_line( $self->result_for($key), $key);
}

1;
