package Roland::Table::FITB;

use Moose;
extends 'Roland::Table::Dictionary';

use namespace::autoclean;

use Roland::Result::FITB;

has template => (
  is => 'ro',
  required => 1,
);

around _args_from_data => sub {
  my ($orig, $class, $name, $data, $hub) = @_;
  $class->$orig($name, $data, $hub);
};

around roll_table => sub {
  my ($orig, $self, @rest) = @_;

  my $dict = $self->$orig(@rest);

  return Roland::Result::FITB->new({
    dict     => $dict,
    template => $self->template,
  });
};

1;
