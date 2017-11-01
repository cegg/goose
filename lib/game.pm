#!/usr/bin/env perl

package game;

use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin; # might or might not be installed
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use Readonly;

use player;

our $VERSION = q[0.0.1];

Readonly::Hash our %magic_numbers => (
  win           => 63,
  goose_end     => 27,
  bridge        => 6,
  bridge_target => 12
);

Readonly::Scalar our $ROLL_LOW  => 1;
Readonly::Scalar our $ROLL_HIGH => 6;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                    %magic_numbers
                    $ROLL_LOW
                    $ROLL_HIGH
                    );

sub new {
  my $class = shift;
  my $self  = {
                name => shift,
                players => []
              };

  return bless $self, $class;
}


sub turn {

  my $self     = shift;
  my $args     = shift;
  if ($args->{action} eq q[reset]) {
    $self->players([]);
    return qq[new game\n];
  } elsif ($args->{action} eq q[add]) {
    if (scalar  @{$self->players} < 2) {
      if (defined $self->players->[0] && $self->players->[0]->name eq $args->{player} ) {
        return qq[$args->{player}: already existing player\n];
      } else {
        $self->add_player(new player($args->{player}));
        #push @{$self->{players}}, new player($args->{player});
        ${$self->players}[$#{$self->players}]->position(0);
        my $players_string = q[];
        foreach  (@{$self->players}) { $players_string .= $_->name() . q[ ] };
        return join q[ ],  (
                            q[players: ],
                            $players_string,
                            qq[\n]
                          );

      }
    } else {
      return qq[there are already two players. you can start moving them now\n];
    }
  } elsif ($args->{action} eq q[move]) {
    if (scalar  @{$self->players} < 1) {
      return qq[add the first player before moving anybody\n];
    } elsif (scalar  @{$self->players} < 2) {
      return qq[add the second player before moving anybody\n];
    } elsif (defined $self->player_active
        && ($args->{player} eq $self->player_active->name)) {
      return join q[ ], (
                          qq["$args->{player}"],
                          q[just moved. it's turn of],
                          q["] . $self->player_inactive->name . q["],
                          qq[\n]
                          );
    } else {
      if ($args->{player} eq $self->players->[0]->name) {
        $self->player_active($self->players->[0]);
        $self->player_inactive($self->players->[1]);
      } elsif ($args->{player} eq $self->players->[1]->name) {
        $self->player_active($self->players->[1]);
        $self->player_inactive($self->players->[0])
      } else {
        my $available;
        foreach  (@{$self->players}) {
          $available .= ($_->name() . q[ ]);
        }
        return join q[ ], (
                            qq[player $args->{player} does not exist. available are: ],
                            $available,
                            qq[\n]
                          );
      }
      # user errors end here and the game can start

      if (!defined $args->{roll_1}) { # move on generated dice roll
        $args->{roll_1} = int(rand(5)) + 1;
        $args->{roll_2} = int(rand(5)) + 1;
      }

      $self->player_active->previous_position($self->player_active->position);
      $self->player_active->roll_sum($args->{roll_1} + $args->{roll_2});
      $self->player_active->target_position($self->player_active->position + $self->player_active->roll_sum);
      $self->player_active->position($self->player_active->target_position);
      my $stops = $self->player_active->apply_rules;

      if ($stops->[0] >= $game::magic_numbers{win}) { # 63
        print join q[ ], (
                          $self->player_active->name, qq[moves to $game::magic_numbers{win}.], $self->player_active->name, qq[wins!\n]
                        );

        print qq[GAME OVER\n];
        exit; # no point to continue to prank
      }

      my $msg_prank = q[];
      if ($self->player_active->position == $self->player_inactive->position) { # prank
        $msg_prank =  join q[ ],  (
                            q[on],
                            $self->player_active->position,
                            q[there is],
                            $self->player_active->name,
                            q[, who returns to ],
                            $self->player_active->previous_position ,
                            qq[\n]
                          );
        $self->player_inactive->position($self->player_active->previous_position);
      }

      print $self->draw_board();
      return  join q[ ], (
                        qq[$args->{player} rolls $args->{roll_1}, $args->{roll_2}.],
                        $self->player_active->compose_message($stops),
                        $msg_prank,
                        qq[\n]
                      );
    }
  }
}

sub draw_board { #debug tool
  my $self    = shift;

  my $board   = join q[ ], ( $self->players->[0]->name, q[=<1>,], $self->players->[1]->name, qq[=<2>\n\n|] );

  for my $cell (1..$game::magic_numbers{win}) {
    if ($cell == $self->players->[0]->position) { #TODO : think how to extend for more than two players, a loop?
      $board .=  (q[ <1>]);
    } elsif ($cell == $self->players->[1]->position) {
      $board .= (q[ <2>]);
    } else {
      $board .=  join q[], ( q[ ], (sprintf "%02d", $cell), q[ ]);
    }
    $board .= q[|];
    if (!($cell % 21)) { # make it wrap
      $board .= qq[\n];
      if ($cell != $game::magic_numbers{win}) {
        $board .= qq[|];
      }
    }
  }
  $board .= qq[\n];
  return $board;
}

sub get_goose_cells_list {
  my $self = shift;
  my $x = 0;
  my $y = 5;
  my $index = 0;
  while ($x+$y <= $game::magic_numbers{goose_end}) { # this generates the magic sequence of "goose" cells with the numbers 5 9 14 18 23 27
    $x += $y;
    push @{$self->{goose_cells}}, $x;
    $index += 1;
    ($index % 2) ? --$y : ++$y;
  }
  return $self->{goose_cells};
}

sub add_player {
  my $self = shift;
  my $player = shift;

  if (defined $player) {
    push @{$self->{players}}, $player;
  }
  return;
}

sub players {
  my $self = shift;
  my $players = shift;
  if (defined $players && (ref $players eq 'ARRAY')) {
    $self->{players} =  $players;
  }

  return $self->{players};
}

sub player_active {
  my $self = shift;
  my $player = shift;

  if (defined $player && $player) {
    $self->{player_active} = $player;
  }
  return $self->{player_active};
}

sub player_inactive {
  my $self = shift;
  my $player = shift;

  if (defined $player && $player) {
    $self->{player_inactive} = $player;
  }
  return $self->{player_inactive};
}

=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - instantiate player object

=head2 turn - "add", "move" or "reset" turn

=head2 draw_board - debug tool

=head2 get_goose_cells_list - generates sequence 5, 9, 14, 18, 23, 27

=head2 players - set or return list of players

=head2 player_active - set or return active_player

=head2 player_inactive - set or return inactive_player

=head2 add_player - push a player object into the list of players

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item English

=item FindBin

=item File::Spec

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Igor Pozdnyakov,,,$

=head1 LICENSE AND COPYRIGHT

=over

=item strict

=item warnings

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
