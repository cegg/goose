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
  win           => 63,
  goose_end     => 27,
  bridge        => 6,
  bridge_target => 12
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

  if (defined $position && $position ne q[]) { # check for q[] accomoodates possible zero
    $self->{position} = $position;
  }
  return $self->{position};
}


sub previous_position {
  my $self     = shift;
  my $previous_position = shift;

  if (defined $previous_position && $previous_position ne q[]) { # check for q[] accomoodates possible zero
    $self->{previous_position} = $previous_position;
  }
  return $self->{previous_position};
}

sub apply_rules {
  my $self = shift;

  $self->clear_stops;
  if ($self->position >= $player::magic_numbers->{win}) {
    $self->add_stop($player::magic_numbers->{win});
    return [$magic_numbers->{win}];
  } elsif ($self->position == $player::magic_numbers->{bridge}) { # totally random jump
    $self->add_stop($player::magic_numbers->{bridge});
    $self->add_stop($player::magic_numbers->{bridge_target});
    $self->position($player::magic_numbers->{bridge_target});
    return $self->stops;
  } else {
    return $self->check_goose_cells($self->position);
  }
  return 0;
}

sub check_goose_cells {
  my $self = shift;
  my $position = shift;
  $self->position($position);
  $self->add_stop($self->position);

  foreach my $goose (@{$main::goose_cells}) { # goose cell - repeat
    if ($position == $goose) {
      $self->check_goose_cells($position + $self->roll_sum);
      last;
    }
  }
  return $self->stops;
}

sub stops {
  my $self = shift;
  return $self->{stops};
}

sub add_stop {
  my $self = shift;
  my $stop = shift;
  push @{$self->{stops}}, $stop;
  return;
}

sub clear_stops {
  my $self = shift;
  $self->{stops} = [];
  return;
}

sub roll_sum {
  my $self = shift;
  my $roll_sum = shift;
  if (defined $roll_sum && $roll_sum) {
    $self->{roll_sum} = $roll_sum;
  }
  return $self->{roll_sum};
}

sub compose_message {
  my $self = shift;
  my $stops = shift;
  my $msg = q[];

  # if ($stops->[0] >= $player::magic_numbers->{win}) { # 63
  #   $msg =  join q[ ], ($self->name, qq[wins!\n\n]);

  if (scalar @{$stops}) { # random jumps, second roll. special wording about the bridge
    if ((scalar @{$stops} == 2) && ($stops->[0] == $player::magic_numbers->{bridge}) && ($stops->[1] == $player::magic_numbers->{bridge_target})) {
      $msg = join q[ ], (
                          $self->name, qq[ moves to the Bridge.],
                          $self->name, qq[jumps to ], $self->position
                        );
    } else {
      my $stop_counter = 0;

      foreach my $stop (@{$stops}) {
        my $again = q[];
        if ($stop_counter > 0) {
          $again = q[again and goes];
        } else {
           $again = q[];
        }

        $msg .= q[ ] . join q[ ], (
                            $self->name, qq[moves $again to $stop.]
                          );
        $stop_counter++;
      }
    }
  }
  return $msg;
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

=head2 compose_message - turn final state description

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
