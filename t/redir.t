use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Hub;
use Roland::Roller::Test;

test_result("monster/man, with zombies" => {
  file  => 'eg/monster/man',
  rolls => [
    3, # number appearing

    8, # hit points
    2, # infected!

    7, # hit points as human
    1, # a zombie!
    6, # hit points as a zombie

    5, # hit points
    4, # no
  ],
  test  => sub {
    my @results = flatten_multi($_[0]);
    is(@results, 2, "we got one man result, one zombie result");

    my @men     = $results[0]->units;
    my @zombies = $results[1]->units;

    is(@men,     2, "...there are two men");
    is($men[0]{hp}, 8, "... ...first with 8 hp");
    is($men[1]{hp}, 5, "... ...second with 5 hp");
    is(@zombies, 1, "...there is one zombie");
    is($zombies[0]{hp}, 6, "... ...with 6 hp");
  },
});

done_testing;
