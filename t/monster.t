use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Table::Monster;

sub xp_for {
  my ($hd, $bonus_ct) = @_;
  my $xp = Roland::Table::Monster->_xp_for_monster({
    hd => $hd,
    'xp-bonuses' => [ (1 .. $bonus_ct) ],
  });
}

sub xp_is {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is(xp_for($_[0], $_[1]), $_[2], "HD: $_[0]; Bonuses: $_[1]; XP = $_[2]");
}

xp_is('<1',  0, 5);
xp_is('< 1', 1, 6);

xp_is('1-1', 0, 5);
xp_is('1-1', 1, 6);
xp_is('1-2', 0, 5);

xp_is( 1, 0, 10);
xp_is( 1, 1, 11);
xp_is( 1, 2, 12);
xp_is( 1, 0, 10);

xp_is('1+1', 0, 15);
xp_is('1+1', 1, 16);
xp_is('1+2', 1, 16);

xp_is('10-2', 6, 5100);
xp_is('10+2', 6, 5100);

xp_is(0,  0, 0); # Is this really something to guarantee? -- rjbs, 2012-12-06
xp_is('?', 1, '?');
xp_is('10d8/2', 1, '?');

done_testing;
