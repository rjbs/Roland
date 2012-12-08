package Roland::Table::Constant;
# ABSTRACT: a table with only one result
use Moose;
with 'Roland::Table';

use namespace::autoclean;

# allow a coderef to be a factory..? -- rjbs, 2012-12-06
has result => (
  is  => 'ro',
  isa => 'Object',
  required => 1,
);

sub roll_table { $_[0]->result }

1;
