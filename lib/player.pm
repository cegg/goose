# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author: rmp
#
package player;
use strict;
use warnings;
use CGI::Carp;
use Readonly;
use English qw(-no_match_vars);

our $VERSION = q[0.0.1];

our $magic_numbers = {
  win => 63,
  goose_end => 27
};

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
                    $magic_numbers
                    );

sub new {
  my $class = shift;
  my $self  = {
                name => shift,
              };
  return bless $self, $class;
}

sub save {
  my $self     = shift;

  return;
}

sub move {
  my $self     = shift;
  my $roll1 = shift;
  my $roll2 = shift;

  return;
}

sub name {
  my $self = shift;
  my $name = shift;
  if (defined $name && $name) {
    $self->{name} = $name;
  }
  return $self->{name};
}

sub position {
  my $self     = shift;
  my $position = shift;

  if (defined $position && $position) {
    $self->{position} = $position;
  }
  return $self->{position};
}

sub apply_rules {
  my $self = shift;
  if ($self->position >= $magic_numbers->{win}) {
     return 1;
  } elsif ($self->position == 6) { # totally random jump
    return 12;
  } else {
    my $goose = [];
    my $x = 0;
    my $y = 5;
    my $index = 0;
#TODO externalize and cache this generator
    while ($x+$y <= $magic_numbers->{goose_end}) { # this generates the magic sequence of "goose" cells with the numbers 5 9 14 18 23 27
      $x += $y;
      push @{$goose}, $x;
      $index += 1;
      if ($index % 2) {
        --$y;
      } else {
        ++$y;
      }

    }
    print "goose: @{$goose}\n";
    foreach my $goose (@{$goose}) {
      if ($self->position == $goose) {
        return $self->position  + $self->roll_sum;
        last;
      }
    }

  }
  return 0;
}

sub roll_sum {
  my $self = shift;
  my $roll_sum = shift;
  if (defined $roll_sum && $roll_sum) {
    $self->{roll_sum} = $roll_sum;
  }
  return $self->{roll_sum};
}

=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - instantiate player object

=head2 move - move player to the new position

=head2 position - returns current position of the user; sets if a value passed

=head2 roll_sum - sums up first and second dice rolls

=head2 apply_rules - checks if currnet postition requires further movements according to the rules of the game

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Igor Pozdnyakov,,,$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
