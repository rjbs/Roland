use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Hub;
use Roland::Roller::Test;

use Roland::Table::FITB;

my $hub = Roland::Hub->new({
  roller => Roland::Roller::Test->new({
    planned_rolls => [],
    pick_n => sub { die "too many" unless $_[1] == 1; $_[2][-1] },
  }),
});

my $table = Roland::Table::FITB->new({
  name    => 'FITB Test',
  hub     => $hub,

  template  => 'The %{adj}i %{noun}i',
  _things   => {
    adj => {
      type  => 'list',
      pick  => 1,
      items => [ qw(Hot Cold Fun Stupid Big Little Wide) ],
    },
    noun => {
      type  => 'list',
      pick  => 1,
      items => [ qw(Knife Clam Bug Abbot Lama Robot) ],
    },
  },
});

my $result = $table->roll_table;

is(
  $result->as_inline_text,
  'The Wide Robot',
  "we can fill in a tavern name",
);

done_testing;
