package Roland::Result::Monster;
use Moose;
with 'Roland::Result';

use namespace::autoclean;

use Data::Bucketeer;
use Text::Autoformat;
use YAML::Tiny;

has name  => (is => 'ro');
has hit_dice => (is => 'ro');
has damage   => (is => 'ro');
has armor_class => (is => 'ro');
has movement    => (is => 'ro');
has xp_per_unit => (is => 'ro');

has units => (
  isa => 'ArrayRef',
  traits => [ 'Array' ],
  handles  => { units => 'elements' },
  required => 1,
);

has extras => (
  isa     => 'HashRef',
  traits  => [ 'Hash' ],
  default => sub {  {}  },
  handles => {
    _extra_keys => 'keys',
    _get_extra  => 'get',
  },
);

sub from_data {
  my ($class, $data, $hub) = @_;

  # TODO: barf about extra table entries?
  my $main = shift @$data;
  my $name = $main->{Name} // "(unknown)";
  my $num_dice = $main->{stats}{'No. Appearing'} // '?';
  $num_dice = $num_dice->{wandering} if ref $num_dice;
  my $num = $num_dice =~ /d/ ? $hub->roll_dice($num_dice, "number of $name")
                             : $num_dice;

  my $HD = $main->{stats}{'Hit Dice'} // '?';
  my @hd = split /\s+/, $HD;
  my $hd = do {
    local $" = '';
    my $d = $hd[0] !~ /d/ ? 'd8' : '';
    "$hd[0]$d@hd[ 1 .. $#hd]"
  };

  my @units = $num eq '?'
    ? ()
    : map {; { hp => $hub->roll_dice($hd, "$name \#$_ hp") } } 1 .. $num;

  my %extra;
  for my $extra (@{ $main->{extras} || [] }) {
    my $desc = $extra->{description};

    my $result = $hub->roll_table([$extra], "$name/$desc");
    # TODO reinstate encounter redirects
    $extra{ $desc } = $result;
  }

  for my $unit_extra (@{ $main->{'per-unit'} || [] }) {
    my $desc = $unit_extra->{description};

    UNIT: for my $unit (@units) {
      my $result = $hub->roll_table([$unit_extra], "$name/$desc");
      # TODO reinstate unit redirects

      $unit->{ $desc } = $result;
    }
  }

  my $ac  = $main->{stats}{'Armor Class'} // '?';
  my $mv  = $main->{stats}{Movement}      // '?';
  my $dmg = $main->{stats}{Damage}        // '?';

  my $xp   = $class->xp_for_monster($main) || '?';
  my $xp_t = $xp eq '?' ? '?' : $num * $xp;

  return $class->new(
    name  => $name,
    hit_dice => $HD,
    damage   => $dmg,
    armor_class => $ac,
    movement    => $mv,
    xp_per_unit => $xp,

    extras => \%extra,
    units  => \@units,
  );
}

sub as_text {
  my ($self, $indent) = @_;
  $indent //= 0;

  my $name = $self->name;
  my $hd   = $self->hit_dice;
  my $ac   = $self->armor_class;
  my $mv   = $self->movement;
  my $dmg  = $self->damage;

  my @units  = $self->units;
  my $num    = @units;
  my $xp_per = $self->xp_per_unit;
  my $xp_tot = $xp_per * $num;

my $text = <<"END_MONSTER";

$name
  No. Appearing: $num
  Hit Dice: $hd
  Stats: [ AC $ac, Mv $mv, Dmg $dmg ]
  Total XP: $xp_tot ($num x $xp_per xp)
END_MONSTER

  for my $key ($self->_extra_keys) {
    next unless defined(my $v = $self->_get_extra($key));
    $v = $v->as_text;
    if ($indent * 2  +  length($v)  +  length($key)  +  4  >  79) {
      $v = autoformat $v, { left => 4, right => 79, all => 1 };
      $text .= "  $key:\n$v";
    } else {
      $text .= "  $key: $v\n";
    }
  }

  for my $unit ($self->units) {
    if (ref $unit) {
      my $hp = delete $unit->{hp};
      $text .= "- Hit points: $hp\n";
      for my $key (sort keys %$unit) {
        next unless defined $unit->{$key};
        $text .= "  $key: " . $unit->{$key}->as_text . "\n";
      }
    } else {
      my $unit_text = $unit;
      $unit_text =~ s/^/  /mg;
      substr $unit_text, 0, 1, '-';
      $text .= $unit_text;
    }
  }

  $text =~ s{^}
            {'  ' x ($indent // 0)}egm;

  return $text;
}

my $XP_LOOKUP = Data::Bucketeer->new('>=' => {
  0.9 => sub { [    5,    1 ] },
  1.0 => sub { [   10,    1 ] },
  1.1 => sub { [   15,    1 ] },
  2.0 => sub { [   20,    5 ] },
  2.1 => sub { [   25,   10 ] },
  3.0 => sub { [   50,   15 ] },
  3.1 => sub { [   50,   25 ] },
  4.0 => sub { [   75,   50 ] },
  4.1 => sub { [  125,   75 ] },
  5.0 => sub { [  175,  125 ] },
  5.1 => sub { [  225,  175 ] },
  6.0 => sub { [  350,  225 ] },
  6.1 => sub { [  350,  300 ] },
  7.0 => sub { [  450,  400 ] },
  8.0 => sub { [  650,  550 ] },
  9.0 => sub { [  900,  700 ] },
  11  => sub { [ 1100,  800 ] },
  13  => sub { [ 1350,  950 ] },
  17  => sub { [ 2000, 1150 ] },
  21  => sub {
    my $hd   = int $_;
    my $over = $hd - 21;
    return [
      2500 + 250 * $over,
      2000,
    ];
  },
});

sub xp_for_monster {
  my ($self, $monster) = @_;
  my $bonuses = @{ $monster->{'XP Bonuses'} // [] };

  return 0 unless my $hd = $monster->{stats}{'Hit Dice'};
  my ($dice, $sign, $bonus) = split /\s+/, $hd, 3;
  $bonus = ($sign || $bonus) ? "$sign$bonus" : 0;

  if ($dice =~ /d/) {
    my ($num, $type) = split /d/, $dice, 2;
    die "confused about hit dice: $hd" if $type != 8 and $num != 1;
    if ($type > 8) { $bonus = 1  };
    if ($type < 8) { $bonus = -1 }
    $dice = $num;
  }

  my $d8 = $dice;
  $d8 += $bonus > 0 ? .1 : $bonus < 0 ? -.1 : 0;

  my $pair = $XP_LOOKUP->result_for($d8);
  return($pair->[0] + $pair->[1] * $bonuses);
}

1;
