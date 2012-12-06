use strict;
use warnings;

use Test::More;

use Roland::Hub;
use Roland::Roller::Test;

sub error_ok {
  my ($result, $resource, $error_like, $desc) = @_;
  $desc //= "error with $resource";

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  isa_ok($result, 'Roland::Result::Error', $desc);
  is($result->resource, $resource, "$desc: resource string");
  like($result->error, $error_like, "$desc: error message");
}

my $hub = Roland::Hub->new;

error_ok(
  $hub->load_table_file()->roll_table,
  '?',
  qr/no filename given/,
);

error_ok(
  $hub->load_table_file('eg/404')->roll_table,
  'eg/404',
  qr/file not found/,
);

error_ok(
  $hub->load_table_file('eg/errors/broken-yaml')->roll_table,
  'eg/errors/broken-yaml',
  qr/YAML/,
);

error_ok(
  $hub->load_table_file('eg/errors/empty')->roll_table,
  'eg/errors/empty',
  qr/file contained no documents/,
);

error_ok(
  $hub->load_table_file('eg/errors/cant-guess-type')->roll_table,
  'eg/errors/cant-guess-type',
  qr/no idea what to do/,
);

error_ok(
  $hub->load_table_file('eg/errors/unknown-type')->roll_table,
  'eg/errors/unknown-type',
  qr/don't know how to handle/,
);

done_testing;
