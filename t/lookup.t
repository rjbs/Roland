use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Hub;
use Roland::Roller::Test;

use Roland::Table::Lookup;

my $hub = Roland::Hub->new({
  roller => Roland::Roller::Test->new({
    planned_rolls => [],
    pick_n => sub { die "too many" unless $_[1] == 1; $_[2] },
  }),
});

my $table = Roland::Table::Lookup->new({
  name    => 'Lookup Test',
  hub     => $hub,

  key     => 'xyzzy',
  default => 'foo',
  lookup  => {
    foo  => '123',
    bar  => '456',
    quux => '789',
  },
});

my $result = $table->roll_table({
  foo   => 'quux',
  xyzzy => 'bar',
  ''    => 'foo',
});

is(
  $result->as_inline_text,
  '456',
  "we can do a lookup",
);

done_testing;
