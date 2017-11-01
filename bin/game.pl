#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use English qw(-no_match_vars);
use FindBin; # might or might not be installed
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');

use game;
use player;

$SIG{INT}  = \&signal_handler;
$SIG{TERM} = \&signal_handler;

our $VERSION = q[0.0.1];

our  %OPTIONS = (
  help  => qq[$PROGRAM_NAME v$VERSION

     The Game of the Goose.

     --help            # this help
     --rules           # prints rules

     available commands:
     >> add player <player_name>
     >> move player
     >> move player <roll1>, <roll2>
     >> reset
     >> exit
     >> quit


     <player_name> should be \\w+
     <roll1> and <roll2> should be \\d{$game::ROLL_LOW,$game::ROLL_HIGH}
     ],

  rules => qq[\nsee https://github.com/xpeppers/goose-game-kata/\n],
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
    print qq[-------------------------------------\nenter command >> ];
    my $user_input_string = <STDIN>;
    $user_input_string =~ s/^\W+//smx;
    $user_input_string =~ s/\W+$//smx;
    my $args = parse_args($user_input_string);
    if ($args->{error}) {
      print qq[\n$args->{error}\n];
      print_option($OPTIONS{help});
      next ITER;
    }

    my $next_iter = $game->turn($args);
    if ($next_iter) {
      print qq[\n$next_iter\n];
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

  if (!$user_input_string) {
    $args->{error} = qq[no valid command was entered. here's help: \n];
  } elsif (($items->[0] eq q[add])
      && defined $items->[1]
      && ($items->[1] eq q[player])
      && defined $items->[2]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[2];
  } elsif ($items->[0] eq q[move]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[1];
    if (defined $items->[2] && !defined $items->[3]) {
        $args->{error} = qq[move command should end with two integers from $game::ROLL_LOW to $game::ROLL_HIGH each separated by white space or a comma\n];
    } elsif (defined $items->[3]) {
      my @rolls = @{$items}[2..3];
      while (my ($index, $roll) = each @rolls) {
        my $is_between = (sort {$a <=> $b} $game::ROLL_LOW, $game::ROLL_HIGH, $roll)[1] == $roll;
        if (!$is_between) {
          $args->{error} = qq[move command should end with two integers from $game::ROLL_LOW to $game::ROLL_HIGH each separated by white space or a comma\n];
          last;
        } else {
          $args->{ 'roll_' . ++$index } = $roll;
        }
      }
    }
  } elsif ($items->[0] eq q[reset]) {
    $args->{action} = $items->[0];
  } elsif ($items->[0] eq q[exit] || $items->[0] eq q[quit]) {
    exit;
  } else {
    $args->{error} = qq[game command should start with either "add player" or "move", follwed by player's name\nother options are reset, exit and quit.\n];
  }
  return $args;
}

sub signal_handler {
  print "exiting. bye\n";
  exit;
}


=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

xpeppers kata take on the classic game of the goose

=head1 SUBROUTINES/METHODS

=head2 parse_args - parse user input command

=head2 print_option - prints help option specified by the user from the command line

=head2 signal_handler - signla handled, Ctrl+C , etc

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=over

=item strict

=item warnings

=item English

=item FindBin

=item File::Spec

=back

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
