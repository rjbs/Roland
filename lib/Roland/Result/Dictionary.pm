package Roland::Result::Dictionary;

# ABSTRACT: a set of ordered name/value results

use Moose;
with 'Roland::Result';

use namespace::autoclean;

use Sort::ByExample;

has results => (
  isa => 'HashRef',
  required => 1,
  traits   => [ 'Hash' ],
  handles  => {
    unordered_keys => 'keys',
    result_for     => 'get',
  },
);

has key_order => (
  isa     => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => {
    key_order => 'elements',
  },
  predicate => 'has_key_order',
);

has ordered_keys => (
  isa     => 'ArrayRef',
  traits  => [ 'Array' ],
  handles => {
    ordered_keys => 'elements',
  },
  init_arg => undef,
  lazy     => 1,
  default  => sub {
    my ($self) = @_;
    return [ $self->unordered_keys ] unless $self->has_key_order;

    my @results = Sort::ByExample->sorter(
      [ $self->key_order ],
      sub { fc $_[0] cmp fc $_[1] },
    )->($self->unordered_keys);

    return \@results;
  },
);

sub inline_text_is_lossy { 1 }
sub as_inline_text { '(table of results)' }

sub as_block_text {
  my ($self, $indent) = @_;
  $indent //= 0;

  my $text = '';

  for my $key ($self->ordered_keys) {
    $text .= sprintf "%s: %s\n",
      $key,
      $self->result_for($key)->as_block_text;
  }

  return $text;
}

1;
