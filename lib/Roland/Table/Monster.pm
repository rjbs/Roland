package Roland::Table::Monster;
# ABSTRACT: a table to generate a monster encounter
use Moose;
with 'Roland::Table';

use Data::Bucketeer;
use List::AllUtils qw(max);
use Roland::Result::Monster;
use Roland::Result::Multi;

use namespace::autoclean;

has _guts => (
  is => 'ro',
);

sub from_data {
  my ($class, $name, $data, $hub) = @_;

  return $class->new({
    name  => $name,
    _guts => $data,
    hub   => $hub,
  });
}

my $HD_RE = qr/\A([0-9]+)(?:\s*([+-])\s*([0-9]+))?\z/;

sub roll_table {
  my ($self, $override) = @_;
  $override //= {};

  # TODO: barf about extra table entries?
  my $main = {
    name => $self->name,
    num  => '?',
    where => 'wandering',

    %{ $self->_guts },
    %$override
  };

  my $name = $main->{name};

  my $num_dice = $self->_result_for_line(
    $main->{num},
    "number appearing",
    $main,
  )->as_inline_text;

  my $num = $num_dice =~ /d/
          ? $self->hub->roll_dice($num_dice, "number of $name")
          : $num_dice;

  my @also;
  my %extra;
  EXTRA: for my $extra_key (sort keys %{ $main->{extras} || {} }) {
    my $desc = $extra_key;

    my $result = eval {
      $self->_result_for_line(
        $main->{extras}{$extra_key},
        "extra::$desc",
        $main,
      );
    };

    unless ($result) {
      my $error = $@;
      if (eval { $error->isa('Roland::Redirect::Replace') }) {
        return $error->actual_result;
      }
      if (eval { $error->isa('Roland::Redirect::Append') }) {
        push @also, $error->actual_result
          unless $error->actual_result->isa('Roland::Result::None');
        next EXTRA;
      }
      die $error;
    }

    $extra{ $desc } = $result;
  }

  # hd is hit dice; either "int1" or "int1 ± int2" or "< 1"
  # hd is used for monster level, xp, etc
  # hp is the hp generator; default based on hd
  #   hd eq "< 1", 1d4
  #   otherwise max(1, roll( "1d{int1} ± {int2}") )
  my $hd = $main->{hd} // '?';

  my $hp = $main->{hp}
        //($hd eq '?'         ? '1d8'
        :  $hd =~ /\A<\s*1\z/ ? '1d4'
        :  $hd =~ $HD_RE      ? $1 . 'd8' . ($2 ? "$2$3" : '')
        :                       '?'); # warn? -- rjbs, 2012-12-06

  my @units;
  if ($num ne '?') {
    UNIT: for (1 .. $num) {
      my $unit = { hp => max(1, $self->hub->roll_dice($hp, "$name \#$_ hp")) };

      for my $unit_extra (@{ $main->{'per-unit'} || [] }) {
        my $desc = $unit_extra->{label};

        my $result = eval {
          $self->build_and_roll_table("unit-extra::$desc", $unit_extra);
        };

        unless ($result) {
          my $error = $@;
          if (eval { $error->isa('Roland::Redirect::Replace') }) {
            push @also, $error->actual_result;
            next UNIT;
          }
          die $error;
        }

        $unit->{ $desc } = $result;
      }

      push @units, $unit;
    }
  }

  my $ac  = $main->{ac}      // '?';
  my $mv  = $main->{mv}      // '?';
  my $dmg = $main->{damage}  // '?';
  my $atk = $main->{attacks} // '?';

  my $xp   = $self->_xp_for_monster($main) || '?';
  my $xp_t = $xp eq '?' ? '?' : $num * $xp;

  my $thac0 = $self->_thac0_for_monster($main) || '?';

  my $result = Roland::Result::Monster->new(
    name     => $name,
    where    => $main->{where},
    hit_dice => $hd,
    hp_dice  => $main->{hp},
    damage   => $dmg,
    attacks  => $atk,
    thac0    => $thac0,
    armor_class => $ac,
    movement    => $mv,
    xp_per_unit => $xp,
    saves       => $main->{saves} // [ $self->_saves_for_monster($main) ],

    extras => \%extra,
    units  => \@units,
  );

  my @final;
  push @final, $result if @units or $num eq '?';
  push @final, @also;

  return @final  > 1 ? Roland::Result::Multi->new({ results => [ @final ] })
       : @final == 1 ? $final[0]
       :               Roland::Result::None->new;
}

my $LOOKUP = Data::Bucketeer->new('>=' => {
               # BASE XP | BONUS XP | THAC0
   0.9 => sub { [    5,           1,     19 ] },
   1.0 => sub { [   10,           1,     19 ] },
   1.1 => sub { [   15,           1,     18 ] },
   2.0 => sub { [   20,           5,     18 ] },
   2.1 => sub { [   25,          10,     17 ] },
   3.0 => sub { [   50,          15,     17 ] },
   3.1 => sub { [   50,          25,     16 ] },
   4.0 => sub { [   75,          50,     16 ] },
   4.1 => sub { [  125,          75,     15 ] },
   5.0 => sub { [  175,         125,     15 ] },
   5.1 => sub { [  225,         175,     14 ] },
   6.0 => sub { [  350,         225,     14 ] },
   6.1 => sub { [  350,         300,     13 ] },
   7.0 => sub { [  450,         400,     13 ] },
   7.1 => sub { [  450,         400,     12 ] },
   8.0 => sub { [  650,         550,     12 ] },
   9.0 => sub { [  900,         700,     12 ] },
   9.1 => sub { [  900,         700,     11 ] },
  11   => sub { [ 1100,         800,     11 ] },
  11.1 => sub { [ 1100,         800,     10 ] },
  13   => sub { [ 1350,         950,     10 ] },
  13.1 => sub { [ 1350,         950,      9 ] },
  15.1 => sub { [ 1350,         950,      8 ] },
  17   => sub { [ 2000,        1150,      7 ] },
  21   => sub {
    my $hd   = int $_;
    my $over = $hd - 21;
    return [
      2500 + 250 * $over,
      2000,
      7,
    ];
  },
});

sub __hd_key {
  my ($self, $hd) = @_;

  my $key = $hd eq '?'         ? return('?')
          : $hd =~ /\A<\s*1\z/ ? '0.9'
          : $hd =~ $HD_RE      ? $1 + ($2 ? ($2.'.1') : '0')
          :                      return('?'); # warn? -- rjbs, 2012-12-06

  return $key;
}

sub _xp_for_monster {
  my ($self, $monster) = @_;
  my $bonuses = @{ $monster->{'xp-bonuses'} // [] };

  return 0 unless my $hd = $monster->{hd};

  my $key = $self->__hd_key($hd);

  my $pair = $LOOKUP->result_for($key);
  return($pair->[0] + $pair->[1] * $bonuses);
}

sub _thac0_for_monster {
  my ($self, $monster) = @_;

  return 20 unless my $hd = $monster->{hd};

  my $key = $self->__hd_key($hd);

  my $tuple = $LOOKUP->result_for($key);
  return($tuple->[2]);
}

my %SAVE = (
  C => [
    [ qw( 11  12  14  16  15 ) ] x 4,
    [ qw(  9  10  12  14  12 ) ] x 4,
    [ qw(  6   7   9  11   9 ) ] x 4,
    [ qw(  3   5   7   8   7 ) ] x 4,
  ],
  D => [
    [ qw(  8   9  10  13  12 ) ] x 3,
    [ qw(  6   7   8  10  10 ) ] x 3,
    [ qw(  4   5   6   7   8 ) ] x 3,
    [ qw(  2   3   4   4   6 ) ] x 3,
  ],
  E => [
    [ qw( 12  13  13  15  15 ) ] x 3,
    [ qw( 10  11  11  13  12 ) ] x 3,
    [ qw(  8   9   9  10   0 ) ] x 3,
    [ qw(  6   7   8   8   8 ) ],
  ],
  F => [
    [ qw( 12  13  14  15  16 ) ] x 3,
    [ qw( 10  11  12  13  14 ) ] x 3,
    [ qw(  8   9  10  10  12 ) ] x 3,
    [ qw(  6   7   8   8  10 ) ] x 3,
    [ qw(  4   5   6   5   8 ) ] x 3,
  ],
  M => [
    [ qw( 13  14  13  16  15 ) ] x 5,
    [ qw( 11  12  11  14  12 ) ] x 5,
    [ qw(  8   9   8  11   8 ) ] x 5,
  ],
  N => [
    [ qw( 14  15  16  17  18 ) ],
  ],
  T => [
    [ qw( 13  14  13  16  15 ) ] x 4,
    [ qw( 12  13  11  14  13 ) ] x 4,
    [ qw( 10  11   9  12  10 ) ] x 4,
    [ qw(  8   9   7  10   8 ) ] x 4,
  ],
);

sub _saves_for_monster {
  my ($self, $monster) = @_;
  my @wtf = ('?') x 5;
  return @wtf unless $monster->{save};
  my ($type, $level) = $monster->{save} =~ /\A([A-Z])(.*)\z/;

  return @wtf unless $type;
  $level //= 1;
  $level--;
  my $saves = $SAVE{$type}[$level];
  return $saves ? @$saves : @wtf;
}

1;
