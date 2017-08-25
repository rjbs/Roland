package Roland::Result::Monster;

# ABSTRACT: a monster encounter

use Moose;
with 'Roland::Result';

use namespace::autoclean;

use Data::Bucketeer;
use Text::Autoformat;

has name  => (is => 'ro');
has where => (is => 'ro');
has hit_dice => (is => 'ro');
has damage   => (is => 'ro');
has attacks  => (is => 'ro');
has saves    => (is => 'ro');
has armor_class => (is => 'ro');
has movement    => (is => 'ro');
has xp_per_unit => (is => 'ro');
has attack_bonus => (is => 'ro');

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

sub inline_text_is_lossy { 1 }

sub as_inline_text {
  my ($self) = @_;
  my @units = $self->units;
  sprintf '(%u x %s)', 0+@units, $self->name;
}

sub as_block_text {
  my ($self, $indent) = @_;
  $indent //= 0;

  my $name  = $self->name;
  my $where = $self->where;
  my $hd    = $self->hit_dice;
  my $ac    = $self->armor_class;
  my $mv    = $self->movement;
  my $dmg   = $self->damage;
  my $atk   = $self->attacks;
  my $attack_bonus = sprintf '%+d', $self->attack_bonus;

  my @units  = $self->units;
  my $num    = @units;
  my $xp_per = $self->xp_per_unit;
  my $xp_tot = $xp_per eq '?' ? '?' : $xp_per * $num;

  $mv = '('
      . (join ", ", map {; "$_: $mv->{$_}" } keys %$mv)
      . ')' if ref $mv;

  my @save  = @{ $self->saves };
  my @label = qw(poison wand petrify breath spell);
  my $saves = join q{, },
              map {; join q{: }, $label[$_], $save[$_] } (keys @label);

my $text = <<"END_MONSTER";

$name ($where)
  No. Appearing: $num
  Hit Dice: $hd
  Stats: [ AC $ac, Mv $mv, Atk $attack_bonus, Dmg $dmg ]
  Attacks: $atk
  Saves  : $saves
  Total XP: $xp_tot ($num x $xp_per xp)
END_MONSTER

  for my $key ($self->_extra_keys) {
    my $v = $self->_get_extra($key);
    next if $v->isa('Roland::Result::None');
    $v = $v->as_block_text; # XXX: as_best_text
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
        next if $unit->{$key}->isa('Roland::Result::None');

        # XXX: as_best_text
        $text .= "  $key: " . $unit->{$key}->as_block_text . "\n";
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

1;
