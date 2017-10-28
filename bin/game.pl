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


  my $opts_parsed = {};

  my @opt_keys = keys %OPTIONS;

  GetOptions($opts_parsed, @opt_keys);

  my @options_startup =  keys %{$opts_parsed};
  if (scalar @options_startup) {
    for my $opt (sort @options_startup) { #user is learning how to run the script
      print "$opt: $opts_parsed->{$opt}\n";
      if(defined $opts_parsed->{$opt}) {
        print_option($OPTIONS{$opt});
      }
    }
    exit;
  }
  reset_game(); #typically that would be called "init", but I use it also for cleanup after the end
  main();


sub main {

  my $players = [];
  my $player_active;
  my $player_inactive;
ITER:  while (1) {
    print 'enter command: ';
    my $user_input_string = <STDIN>;
    my $args = parse_args($user_input_string);

    if ($args->{error}) {
      print $args->{error};
      print_option($OPTIONS{help});
    }
    #print Dumper($args);

    if ($args->{action} eq q[add]) {
      if (scalar  @{$players} < 2) {
        if (defined $players->[0] && $players->[0]->name eq $args->{player} ) {
          print qq[$args->{player}: already existing player\n];
          next ITER;
        } else {
          push @{$players}, new player($args->{player});
          ${$players}[$#{$players}]->position(1);
          print q[players: ]; {foreach  (@{$players}) { print $_->name() . q[ ] }}; print qq[\n];
          next ITER;
          #print q[position: ]; {foreach  (@{$players}) { print $_->position() . q[ ] }}; print qq[\n];
          # print qq[pushing $args->{player}\n];
        }
      } else {
        print qq[there are already two players. you can start moving them now\n];
        next ITER;
      }
    } elsif ($args->{action} eq q[move]) {
      if (scalar  @{$players} < 2) {
        print qq[add the second player before moving anybody\n];
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

        if (!defined $args->{roll_1}) { # move on generated dice roll
          $args->{roll_1} = int(rand(5))+1;
          $args->{roll_2} = int(rand(5))+1;
          #print "generated $args->{roll_1}, $args->{roll_2}\n";
        }

        $args->{target_position} = $player_active->position + $args->{roll_1} + $args->{roll_2};
        print join q[ ], (
          qq[$args->{player} rolls $args->{roll_1}, $args->{roll_2}.],
          $player_active->name,
          qq[moves from],
          $player_active->position,
          qq[to $args->{target_position}\n]
        );
        $player_active->position($args->{target_position});
        print_state($players, $player_active);
      }
    }
  }
  return;
}


sub print_state {
  my $players = shift;
  my $player_active = shift;
  print q[|];
  for my $cell (1..63) {
    if ($cell == $players->[0]->position) { #TODO : not scalable for more players, a loop migh suffice instead
      print $players->[0]->name;
    } elsif ($cell == $players->[1]->position) {
      print $players->[1]->name;
    } else {
      print qq[$cell];
    }
    print q[|];
  }
  print qq[\n];
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
  # foreach my $z  (@{$items}) {
  #   print "INPUT=$z\n";
  # }

  my $args = {};

  if (($items->[0] eq q[add]) && ($items->[1] eq q[player])) {
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

      # foreach my $roll (@{$items}[2..3]) {
      #   my $is_between = (sort {$a <=> $b} $lower, $upper, $roll)[1] == $roll;
      #   #printf "$roll is%s between $lower and $upper\n", $is_between ? "" : " not";
      #   if (!$is_between) {
      #     $args->{error} = qq[move command should end with two integers from 1 to 6 each separated by white space or a comma\n];
      #     last;
      #   } else {
      #     $args->{"roll$roll"} = $roll;
      #   }
      # }
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
  reset_game();
  print "exiting\n";
  exit;
}

sub reset_game {
  my $dir = q[database];
  if (!-d $dir) {
    eval {
      make_path($dir);
    } or do {
      croak qq[Could not create directory $dir: $EVAL_ERROR];
    }
  }
  return;
}





=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 parse_args - parse user input command

=head2 reset_game - remove users that were created during the game; makes sure database dir exist

=head2 print_option - prints help option specified by the user from the command line

=head2 signal_handler - signla handled, Ctrl+C , etc

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
