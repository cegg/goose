#!/usr/bin/env perl

use strict;
use warnings;
use DateTime;
use Getopt::Long;
use English qw(-no_match_vars);
use Carp;
#use lib qw(../lib /opt/goose/lib); # if I get to to the point of making proper deb
use Data::Dumper;
use Readonly;
use Cwd qw(getcwd);
use File::Path qw(make_path);

use FindBin; # might or might not be installed
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use player;

our $VERSION = q[0.0.1];

$SIG{INT} = \&signal_handler;
$SIG{TERM} = \&signal_handler;

our  %OPTIONS = (
  help  => qq[$PROGRAM_NAME v$VERSION

     The Game of the Goose.

     --help            # this help
     --rules           # prints rules

     available commands:
     add player <player_name>
     move player
     move player <roll1>, <roll2>],
  rules => q[all the rules about special positions...],
);

  our $goose_cells = get_goose_cells_list();

  my $opts_parsed = {};

  my @opt_keys = keys %OPTIONS;

  GetOptions($opts_parsed, @opt_keys);

  my @options_startup =  keys %{$opts_parsed};
  if (scalar @options_startup) {
    for my $opt (sort @options_startup) { #user is learning how to run the script
      if(defined $opts_parsed->{$opt}) {
        print_option($OPTIONS{$opt});
      }
    }
    exit;
  }

  main();


sub main {

  my $players = [];
  my $player_active;
  my $player_inactive;

ITER:  while (1) {
    print q[enter command >> ];
    my $user_input_string = <STDIN>;
    $user_input_string =~ s/^\W+//smx;
    $user_input_string =~ s/\W+$//smx;
    my $args = parse_args($user_input_string);

    if ($args->{error}) {
      print $args->{error};
      print_option($OPTIONS{help});
      next ITER;
    }
    #print Dumper($args);

    if ($args->{action} eq q[add]) {
      if (scalar  @{$players} < 2) {
        if (defined $players->[0] && $players->[0]->name eq $args->{player} ) {
          print qq[$args->{player}: already existing player\n];
          next ITER;
        } else {
          push @{$players}, new player($args->{player});
          ${$players}[$#{$players}]->position(0);
          print q[players: ]; {foreach  (@{$players}) { print $_->name() . q[ ] }}; print qq[\n];
          next ITER;
        }
      } else {
        print qq[there are already two players. you can start moving them now\n];
        next ITER;
      }
    } elsif ($args->{action} eq q[move]) {
      if (scalar  @{$players} < 1) {
        print qq[add the first player before moving anybody\n];
        next ITER;
      } elsif (scalar  @{$players} < 2) {
        print qq[add the second player before moving anybody\n];
        next ITER;
      } elsif (defined $player_active
          && ($args->{player} eq $player_active->name)) {
        print join q[ ], (
          qq["$args->{player}"],
          q[just moved. it's turn of],
          q["] . $player_inactive->name . q["],
          qq["\n]
        );
        next ITER;

      } else {
        if ($args->{player} eq $players->[0]->name) {
          $player_active = $players->[0];
          $player_inactive = $players->[1]
        } elsif ($args->{player} eq $players->[1]->name) {
          $player_active = $players->[1];
          $player_inactive = $players->[0];
        } else {
          my $available;
          foreach  (@{$players}) {
            $available .= ($_->name() . q[ ]);
          }
          print join q[ ], (
              qq[player $args->{player} does not exist. available are: ],
              $available,
              qq[\n]
              );
          next ITER;
        }
        # user errors end here and the game can start

        if (!defined $args->{roll_1}) { # move on generated dice roll
          $args->{roll_1} = int(rand(5)) + 1;
          $args->{roll_2} = int(rand(5)) + 1;
        }

        $player_active->previous_position($player_active->position);
        $player_active->roll_sum($args->{roll_1} + $args->{roll_2});
        $args->{target_position} = $player_active->position + $player_active->roll_sum;
        $player_active->position($args->{target_position});
        my $stops = $player_active->apply_rules;

        if ($stops->[0] >= $player::magic_numbers->{win}) { # 63
          print join q[ ], (
                            $player_active->name, qq[moves to $player::magic_numbers->{win}.], $player_active->name, qq[wins!\n]
                          );

          print qq[GAME OVER\n];
          exit; # no point to continue to prank
        }

        my $msg_prank = q[];
        if ($player_active->position == $player_inactive->position) { # prank
          $msg_prank =  join q[ ],  (
                              q[on],
                              $player_active->position,
                              q[there is],
                              $player_active->name,
                              q[, who returns to ],
                              $player_active->previous_position ,
                              qq[\n]
                            );
          $player_inactive->position($player_active->previous_position);
        }


        print_board($players, $player_active);
        print join q[ ], (
                          qq[$args->{player} rolls $args->{roll_1}, $args->{roll_2}. ],
                          $player_active->compose_message($stops),
                          $msg_prank,
                          qq[\n]
                        );
      }
    }
  }
  return;
}

sub print_board { #debug tool
  my $players = shift;
  my $player_active = shift;
  print q[|];
  for my $cell (1..$player::magic_numbers->{win}) {
    if ($cell == $players->[0]->position) { #TODO : not scalable for more players, a loop migh suffice instead
      print q[ <] . $players->[0]->name . q[> ];
    } elsif ($cell == $players->[1]->position) {
      print q[ <] . $players->[1]->name . q[> ];
    } else {
      print qq[$cell];
    }
    print q[|];
  }
  print qq[\n];
  return;
}

sub print_option { #just a placeholder in case if fancier formatting will be introduced
  my $option = shift;
  print qq[$option\n];
  return;
}

sub parse_args {
  my $user_input_string = shift;

  my $items = [];
  @{$items} = split /(?:\s|,)+/, $user_input_string;

  my $args = {};

  if (($items->[0] eq q[add])
      && defined $items->[1]
      && ($items->[1] eq q[player])
      && defined $items->[2]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[2];
  } elsif ($items->[0] eq q[move]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[1];
    my ($lower, $upper) = (1, 6);
    if (! defined $items->[2]) {
      #roll here
    } elsif (defined $items->[3]) {
      my @rolls = @{$items}[2..3];
      while (my ($index, $roll) = each @rolls) {
        my $is_between = (sort {$a <=> $b} $lower, $upper, $roll)[1] == $roll;
        if (!$is_between) {
          $args->{error} = qq[move command should end with two integers from 1 to 6 each separated by white space or a comma\n];
          last;
        } else {
          $args->{ 'roll_' . ++$index } = $roll;
        }
      }
    } else {
      $args->{error} = qq[move command should end with two integers from 1 to 6 each separated by white space or a comma\n];
    }
  } elsif ($items->[0] eq q[exit] || $items->[0] eq q[quit]) {
    reset_game();
    exit;
  } else {
    $args->{error} = qq[command should start with either "add player" or "move", follwed by player's name\n];
  }
  return $args;
}

sub signal_handler {
  print "exiting\n";
  exit;
}

sub get_goose_cells_list {
    my $goose = [];
    my $x = 0;
    my $y = 5;
    my $index = 0;
    while ($x+$y <= $player::magic_numbers->{goose_end}) { # this generates the magic sequence of "goose" cells with the numbers 5 9 14 18 23 27
      $x += $y;
      push @{$goose}, $x;
      $index += 1;
      ($index % 2) ? --$y : ++$y;
    }
  return $goose;
}



=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 parse_args - parse user input command

=head2 print_option - prints help option specified by the user from the command line

=head2 signal_handler - signla handled, Ctrl+C , etc

=head2 get_goose_cells_list - generates sequence 5, 9, 14, 18, 23, 27

=head2 print_board

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
