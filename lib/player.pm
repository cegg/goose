#!/usr/bin/env perl

package player;

use strict;
use warnings;
use English qw(-no_match_vars);

our $VERSION = q[0.0.1];

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

sub target_position {
  my $self     = shift;
  my $target_position = shift;

  if (defined $target_position && $target_position ne q[]) { # check for q[] accomoodates possible zero
    $self->{target_position} = $target_position;
  }
  return $self->{target_position};
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
  if ($self->position >= $game::magic_numbers{win}) {
    $self->add_stop($game::magic_numbers{win});
    return [$game::magic_numbers{win}];
  } elsif ($self->position == $game::magic_numbers{bridge}) { # totally random jump
    $self->add_stop($game::magic_numbers{bridge});
    $self->add_stop($game::magic_numbers{bridge_target});
    $self->position($game::magic_numbers{bridge_target});
    return $self->stops;
  } else {
    return $self->check_goose_cells($self->position); # recursive check for further jumps
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

  if (scalar @{$stops}) { # random jumps, second roll. special wording about the bridge
    if ((scalar @{$stops} == 2) && ($stops->[0] == $game::magic_numbers{bridge}) && ($stops->[1] == $game::magic_numbers{bridge_target})) {
      $msg = join q[ ], (
                          $self->name, qq[ moves to the Bridge.],
                          $self->name, qq[jumps to ], $self->position
                        );
    } else {
      my $stop_counter = 0;

      foreach my $stop (@{$stops}) {
        my $move_clause = q[];
        if ($stop_counter > 0) {
          $move_clause = q[again and goes];
        } else {
          $move_clause = qq[from ] . $self->previous_position;
        }

        $msg .= q[ ] . join q[ ], (
                            $self->name, qq[moves $move_clause to $stop.]
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

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item English

=back

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
