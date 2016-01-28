package t::lib::Roland;
use strict;

use Test::More;

use Sub::Exporter -setup => {
  exports => [ qw(test_result simple_ok flatten_multi error_ok) ],
  groups  => [ default => [ '-all' ] ],
};

sub test_result {
  my ($description, $arg) = @_;

  subtest $description => sub {
    my $hub = Roland::Hub->new({
      roller => Roland::Roller::Test->new({
        random_fallback => $arg->{rand},
        planned_rolls   => $arg->{rolls},
        pick_n          => $arg->{pick_n} || sub {
          my ($self, $n, $max) = @_;
          return( (0 .. $n) );
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
}

sub simple_ok {
  my ($got_result, $want_string, $desc) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  isa_ok($got_result, 'Roland::Result::Simple', $desc);
  is($got_result->text, $want_string, qq{$desc is "$want_string"});
}

sub flatten_multi {
  my ($multi) = @_;

  my @queue  = $multi;
  my @buffer = ();
  while (my $next = shift @queue) {
    if ($next->isa('Roland::Result::Multi')) {
      unshift @queue, $next->results;
      next;
    }
    push @buffer, $next;
  }

  return @buffer;
}

sub error_ok {
  my ($result, $resource, $error_like, $desc) = @_;
  $desc //= "error with $resource";

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  isa_ok($result, 'Roland::Result::Error', $desc);
  is($result->resource, $resource, "$desc: resource string");
  like($result->error, $error_like, "$desc: error message");
}

1;
