use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Hub;
use Roland::Roller::Test;

use Roland::Table::FITB;

my $hub = Roland::Hub->new;

my $table = Roland::Table::FITB->new({
  name    => 'FITB Test',
  hub     => $hub,

  template  => 'The %{adj}s %{noun}s',
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

ok 1;
done_testing;
