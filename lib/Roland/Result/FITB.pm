package Roland::Result::FITB;
use Moose;
with 'Roland::Result';

use namespace::autoclean;

use String::Formatter stringf => {
  -as => '__stringf',
  input_processor => 'require_named_input',
  string_replacer => 'named_replace',

  codes => {
    s => sub { $_ },     # string itself
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

sub as_text {
  my ($self) = @_;

  my $dict = $self->dict;
  my %text_dict = map {; $_ => $dict->result_for($_)->as_text }
                  $dict->unordered_keys;

  return __stringf $self->template, \%text_dict;
}

1;
