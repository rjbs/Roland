package Roland::Table::List;
# ABSTRACT: a table listing possibly-weighted results
use Moose;
with 'Roland::Table';

use namespace::autoclean;

use Roland::Result::Multi;

has pick_count => (
  is  => 'ro',
  isa => 'Int', # > 0 -- rjbs, 2012-12-09
  predicate => 'has_pick_count',
);

sub BUILD {
  my ($self) = @_;
  # TODO check that every weight is unique and in range (0,1] and 1 is here
  # TODO check that every bucket is a known bucket -- rjbs, 2016-01-18
}

has weights => (
  reader  => '_weights',
  isa     => 'HashRef[Int]', # 0 < x <= 100
  lazy    => 1,
  traits  => [ 'Hash' ],
  handles => { weights => 'keys', limit_for_weight => 'get' },
  default => sub {
    my ($self) = @_;
    my @keys = $self->bucket_names;
    my %subhash = {
      common    => 100,
      uncommon  =>  35,
      rare      =>  15,
      very_rare =>   4,
    }->%{ @keys };

    return \%subhash;
  },
);

has buckets => (
  isa => 'HashRef[ArrayRef]', # improve
  required => 1,
  traits   => [ 'Hash' ],
  handles  => {
    bucket_names => 'keys',
    _items_for_weight  => 'get',
  }
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  my %buckets;
  if (ref $data->{items} eq 'HASH') {
    %buckets = %{ $data->{items} };
  } else {
    $buckets{common} = $data->{items};
  }

  return $class->new({
    name    => $name,
    buckets => \%buckets,
    hub     => $hub,
    (defined $data->{pick} ? (pick_count => $data->{pick}) : ()),
  });
}

# This can be optimized into a coderef early on. -- rjbs, 2016-01-19
sub _bucket_for {
  my ($self, $n) = @_;

  my $w = $self->_weights;
  for my $bucket (sort { $w->{$a} <=> $w->{$b} } keys %$w) {
    return $bucket if $n <= $w->{$bucket};
  }

  confess "unreachable code";
}

sub roll_table {
  my ($self) = @_;

  my %bucket;

  if ($self->weights == 1) {
    %bucket = (common => $self->pick_count);
  } else {
    my @rarities = map {;
      $self->hub->roller->roll_dice('1d100', "rarity of roll $_");
    } (1 .. $self->pick_count);

    for my $r (@rarities) {
      $bucket{ $self->_bucket_for($r) }++;
    }
  }

  my @group;

  for my $bucket (keys %bucket) {
    my $pick  = $bucket{ $bucket };
    my $items = $self->_items_for_weight($bucket);

    for my $i ($self->hub->roller->pick_n($pick, $#$items)) {
      my $result = $self->_result_for_line($items->[$i], "item $i");
      next if $result->isa('Roland::Result::None');
      push @group, $result;
    }
  }

  return Roland::Result::None->new unless @group;
  return $group[0] if @group == 1;
  return Roland::Result::Multi->new({ results => \@group });
}

1;
