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
        push @also, $error->actual_result;
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

  my $ac  = $main->{ac} // '?';
  my $mv  = $main->{mv}      // '?';
  my $dmg = $main->{damage}        // '?';

  my $xp   = $self->_xp_for_monster($main) || '?';
  my $xp_t = $xp eq '?' ? '?' : $num * $xp;

  my $result = Roland::Result::Monster->new(
    name     => $name,
    where    => $main->{where},
    hit_dice => $hd,
    hp_dice  => $main->{hp},
    damage   => $dmg,
    armor_class => $ac,
    movement    => $mv,
    xp_per_unit => $xp,

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

sub _xp_for_monster {
  my ($self, $monster) = @_;
  my $bonuses = @{ $monster->{'xp-bonuses'} // [] };

  return 0 unless my $hd = $monster->{hd};

  my $key = $hd eq '?'         ? return('?')
          : $hd =~ /\A<\s*1\z/ ? '0.9'
          : $hd =~ $HD_RE      ? $1 + ($2 ? ($2.'.1') : '0')
          :                      return('?'); # warn? -- rjbs, 2012-12-06

  my $pair = $XP_LOOKUP->result_for($key);
  return($pair->[0] + $pair->[1] * $bonuses);
}

1;
