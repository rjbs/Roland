package Roland::Table::Group;
use Moose;
with 'Roland::Table';

use Roland::Result::Multi;

use namespace::autoclean;

has _guts => (
  is => 'ro',
);

sub from_data {
  my ($class, $data, $hub) = @_;

  # XXX: Make it possible to have a "how many" that's like the "times"
  # option for "table" tables.  Given a long list, it would choose $x items
  # from the list, possibly never picking the same once twice.  That will
  # require being able to specify a "group" table as a mapping, rather than
  # only the then-sugar form of a sequence. -- rjbs, 2012-11-30
  return $class->new({
    _guts => $data,
    hub   => $hub,
  });
}

sub roll_table {
  my ($self) = @_;

  my @list = @{ $self->_guts->{items} };

  my @group;
  for my $i (0 .. $#list) {
    my $result = $self->hub->_result_for_line(
      $list[$i],
      $self,
      "name:$i", # should be our name
    );

    push @group, $result unless $result->isa('Roland::Result::None');
  }

  return Roland::Result::Multi->new({ results => \@group });
}

1;
