use strict;
use warnings;

use Test::More;
use t::lib::Roland;

use Roland::Hub;
use Roland::Roller::Test;

test_result("L1, rolled a 2" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 2 ],
  test  => sub { simple_ok($_, 'Instant death', 'result for 2') },
});

test_result("L1, rolled a 3" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 3 ],
  pick_n => sub { 0 },
  test   => sub { simple_ok($_, 'Cat', 'result for 3 [0]') },
});

test_result("L1, rolled a 4" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 4 ],
  rand   => 1,
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Monster');
  },
});

test_result("L1, rolled a 5" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 5 ],
  rand   => 1,
  pick_n => sub { 1 },
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Multi');
    my @members = $result->results;
    is(@members, 4);

    isa_ok($members[0], 'Roland::Result::Monster', "5 part 1");
    my @units = $members[0]->units;
    is(@units, 1, "5 part 1: we got just one man");
    isa_ok($members[1], 'Roland::Result::Multi',   "5 part 2");
    simple_ok($members[2], 'creek', '5 part 3');
    simple_ok($members[3], 'Panama', '5 part 4');
  },
});

test_result("L1, rolled 6,1" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 6, 1 ],
  test  => sub { simple_ok($_, 'Tinker', 'result for 6,1') },
});

test_result("L1, rolled 6,3" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 6, 3 ],
  test  => sub { simple_ok($_, 'Tailor', 'result for 6,3') },
});

test_result("L1, rolled 6,6" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 6, 6 ],
  pick_n => sub { 2 },
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Dictionary', 'result for 6,6');
    my @slots = $result->ordered_keys;
    is_deeply(\@slots, [ qw(Actually Cover) ], "the right ordered keys");
    simple_ok($result->result_for('Actually') ,'Spy', 'first value');
    simple_ok($result->result_for('Cover') ,'Cooper', 'second value');
  },
});

test_result("L1, rolled 7,2,6,3" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 7,2,6,3 ],
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Multi');

    my @members = $result->results;

    is(@members, 2, 'rolling 7 means we rolled 2x more');
    simple_ok($members[0], 'Instant death', '7,2,...');
    simple_ok($members[1], 'Tailor', '7,2,6,3');
  },
});

test_result("L1, rolled an 8" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 8 ],
  rand   => 1,
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::None');
  },
});

test_result("L3, rolled an 1,2" => {
  file   => 'eg/dungeon/encounters-L3',
  rolls  => [ 1,2 ],
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Multi');

    my @members = $result->results;

    is(@members, 2, 'we always roll twice on L3');
    simple_ok($members[0], 'Robot', 'L3 1');
    simple_ok($members[1], 'Hovering Squid', 'L3 2');
  },
});

test_result("L3, rolled an 1,3,3,4,3,1" => {
  file   => 'eg/dungeon/encounters-L3',
  rolls  => [ 1,3,3,4,3,1 ],
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Multi');

    my @members = flatten_multi($result);

    is(@members, 4, 'nested multirolls on L3');
    simple_ok($members[0], 'Robot', 'L3 1');
    simple_ok($members[1], 'Goblin', 'L3 3.4');
    simple_ok($members[2], 'Kitten', 'L3 3.3');
    simple_ok($members[3], 'Childhood friend', 'L3 3.1');
  },
});

done_testing;
