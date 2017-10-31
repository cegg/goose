#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use English qw(-no_match_vars);
#use lib qw(../lib /opt/goose/lib); # if I get to to the point of making proper deb
use Cwd qw(getcwd);

use FindBin; # might or might not be installed
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use game;
use player;

our $VERSION = q[0.0.1];

$SIG{INT}  = \&signal_handler;
$SIG{TERM} = \&signal_handler;

our  %OPTIONS = (
  help  => qq[$PROGRAM_NAME v$VERSION

     The Game of the Goose.

     --help            # this help
     --rules           # prints rules

     available commands:
     add player <player_name>
     move player
     move player <roll1>, <roll2>
     exit
     quit
     ],

  rules => q[see https://github.com/xpeppers/goose-game-kata/],
);

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

  my $game = new game('goose');
  our $goose_cells = $game->get_goose_cells_list;

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

    my $turn_error = $game->turn($args);
    if ($turn_error) {
      print $turn_error;
      next ITER;
    }
  }
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
    if (defined $items->[2] && !defined $items->[3]) {
        $args->{error} = qq[move command should end with two integers from 1 to 6 each separated by white space or a comma\n];
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
    #} else {
    #  $args->{error} = qq[move command should end with two integers from 1 to 6 each separated by white space or a comma\n];
    }
  } elsif ($items->[0] eq q[exit] || $items->[0] eq q[quit]) {
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
