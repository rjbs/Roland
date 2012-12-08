package Roland::Result::Monster;
use Moose;
with 'Roland::Result';

use namespace::autoclean;

use Data::Bucketeer;
use Text::Autoformat;

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
  my $xp_tot = $xp_per eq '?' ? '?' : $xp_per * $num;

  $mv = '('
      . (join ", ", map {; "$_: $mv->{$_}" } keys %$mv)
      . ')' if ref $mv;

my $text = <<"END_MONSTER";

$name
  No. Appearing: $num
  Hit Dice: $hd
  Stats: [ AC $ac, Mv $mv, Dmg $dmg ]
  Total XP: $xp_tot ($num x $xp_per xp)
END_MONSTER

  for my $key ($self->_extra_keys) {
    my $v = $self->_get_extra($key);
    next if $v->isa('Roland::Result::None');
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
        next if $unit->{$key}->isa('Roland::Result::None');
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

1;
