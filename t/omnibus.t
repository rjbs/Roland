use strict;
use warnings;

use Test::More;

use Roland::Hub;
use Roland::Roller::Test;

sub test_result {
  my ($description, $arg) = @_;
  my $hub = Roland::Hub->new({
    roller => Roland::Roller::Test->new({
      random_fallback => $arg->{rand},
      planned_rolls   => $arg->{rolls},
      pick_n          => $arg->{pick_n} || sub {
        my ($self, $n, $aref) = @_;
        (@$aref)[0 .. $n - 1];
      },
    }),
  });

  my $result = $hub->load_table_file($arg->{file})->roll_table;
  local $Test::Builder::Level = $Test::Builder::Level + 1;

  ok($hub->roller->rolls_exhausted, "used all the dice");

  local $Test::Builder::Level = $Test::Builder::Level + 1;
  local $_ = $result;
  $arg->{test}->($result);
}

sub simple_ok {
  my ($got_result, $want_string, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  isa_ok($got_result, 'Roland::Result::Simple', $desc);
  is($got_result->text, $want_string, qq{$desc is "$want_string"});
}

test_result("rolled a 2" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 2 ],
  test  => sub { simple_ok($_, 'Instant death', 'result for 2') },
});

test_result("rolled a 3" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 3 ],
  pick_n => sub { $_[2][0] },
  test   => sub { simple_ok($_, 'Cat', 'result for 3 [0]') },
});

test_result("rolled a 4" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 4 ],
  rand   => 1,
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Monster');
  },
});

test_result("rolled a 5" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 5 ],
  rand   => 1,
  pick_n => sub { $_[2][1] },
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Multi');
    my @members = $result->results;

    isa_ok($members[0], 'Roland::Result::Monster', "5 part 1");
    my @units = $members[0]->units;
    is(@units, 1, "5 part 1: we got just one man");
    isa_ok($members[1], 'Roland::Result::Multi',   "5 part 2");
    simple_ok($members[2], 'creek', '5 part 3');
    simple_ok($members[3], 'Panama', '5 part 4');
  },
});

test_result("rolled 6,1" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 6, 1 ],
  test  => sub { simple_ok($_, 'Tinker', 'result for 6,1') },
});

test_result("rolled 6,3" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 6, 3 ],
  test  => sub { simple_ok($_, 'Tailor', 'result for 6,3') },
});

test_result("rolled 6,6" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 6, 6 ],
  pick_n => sub { $_[2][2] },
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Dictionary', 'result for 6,6');
    my @slots = $result->_results;
    is($slots[0][0], 'Actually', "first label");
    simple_ok($slots[0][1], 'Spy', 'first value');

    is($slots[1][0], 'Cover', "second label");
    simple_ok($slots[1][1], 'Cooper', 'second value');
  },
});

done_testing;
