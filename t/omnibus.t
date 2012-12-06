use strict;
use warnings;

use Test::More;

use Roland::Hub;
use Roland::Roller::Test;

sub test_result {
  my ($description, $arg) = @_;
  my $hub = Roland::Hub->new({
    roller => Roland::Roller::Test->new({
      planned_rolls => $arg->{rolls},
      pick_n        => $arg->{pick_n} || sub {
        my ($self, $n, $aref) = @_;
        (@$aref)[0 .. $n - 1];
      },
    }),
  });

  my $result = $hub->roll_table_file($arg->{file});
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

test_result("rolled 5,1" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 5, 1 ],
  test  => sub { simple_ok($_, 'Tinker', 'result for 5,1') },
});

test_result("rolled 5,3" => {
  file  => 'eg/dungeon/encounters-L1',
  rolls => [ 5, 3 ],
  test  => sub { simple_ok($_, 'Tailor', 'result for 5,3') },
});

test_result("rolled 5,6" => {
  file   => 'eg/dungeon/encounters-L1',
  rolls  => [ 5, 6 ],
  pick_n => sub { $_[2][2] },
  test   => sub {
    my $result = shift;
    isa_ok($result, 'Roland::Result::Dictionary', 'result for 5,6');
    my @slots = $result->_results;
    is($slots[0][0], 'Actually', "first label");
    simple_ok($slots[0][1], 'Spy', 'first value');

    is($slots[1][0], 'Cover', "second label");
    simple_ok($slots[1][1], 'Cooper', 'second value');
  },
});

done_testing;
