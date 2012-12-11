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

has fallback => (
  is  => 'ro',
  isa => 'Str', # enum([ qw(default fatal random) ]),
  default => 'default',
);

has lookup => (
  isa    => 'HashRef',
  traits => [ 'Hash' ],
  required => 1,
  handles  => {
    lookup_keys => 'keys',
    result_for  => 'get',
    has_result_for => 'exists',
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

  # XXX huge mess -- rjbs, 2012-12-10
  my $result;
  if ($self->has_result_for($key)) {
    $result = $self->result_for($key);
  } else {
    if ($self->fallback eq 'default') {
      $result = $self->result_for( $self->default );
    }
  }

  return $self->_result_for_line( $result, $key);
}

1;
