package Roland::Result::FITB;

use Moose;
with 'Roland::Result';

use namespace::autoclean;

use String::Formatter stringf => {
  -as => '__stringf',
  input_processor => 'require_named_input',
  string_replacer => 'named_replace',

  codes => {
    s => sub { $_ },
    i => sub { $_->as_inline_text },
    b => sub { $_->as_inline_text },
  },
};

has dict => (
  is  => 'ro',
  isa => 'Object',
  required => 1,
);

has template => (
  is => 'ro',
  required => 1,
);

sub inline_text_is_lossy { 0 }

# XXX: These as_X_text methods are a gross hack. -- rjbs, 2012-12-10
sub as_inline_text {
  my ($self) = @_;

  my $dict = $self->dict;
  my %text_dict = map {; $_ => $dict->result_for($_) } $dict->unordered_keys;

  my $str = __stringf $self->template, \%text_dict;
  return $str;
}

sub as_block_text {
  my ($self) = @_;

  $self->as_inline_text . "\n";
}

1;
