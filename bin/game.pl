#!/usr/bin/env perl

use strict;
use warnings;
use DateTime;
use JSON;
use Getopt::Long;
use English qw(-no_match_vars);
use Carp;
use lib qw(lib /opt/goose/lib);
use Data::Dumper;
use Readonly;
use Cwd;
use Config::IniFiles;

our $VERSION = q[0.0.1];

main();

sub main {
  my $opts = {};
  GetOptions($opts, qw(help));

  my $items = \@ARGV;

  if($opts->{help}) {
    print <<"EOT" or croak qq[Error printing: $ERRNO];
$PROGRAM_NAME v$VERSION

 The Game of the Goose.

 --help            # this help

 available command s at the prompt:
 add player <player_name>
 move player
 move player <roll1>, <roll2>

EOT
    exit;
  }
  while (1) {
    print 'enter command: ';
    my $user_input_string = <STDIN>;
    my $user_input = [];
    @{$user_input} = split /(\s|,)+/, $user_input_string;
    print @{$user_input};

    my $args = ParseArgs($user_input);
    if ($args->{error}) {
      print $args->{error};
    } else {
      print $args->{action};

    }
  }
}


sub ParseArgs {
  my $items = shift;
  my $args = {};
  if ($items->[0] eq q[add] && $items->[1] eq q[player]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[2];
  } elsif ($items->[0] eq q[move]) {
    $args->{action} = $items->[0];
    $args->{player} = $items->[1];
    my ($lower, $upper) = (1, 6);
print "action: $args->{action}, player: $args->{player}\n";
    if (! defined $items->[2]) {

    } else {
      for my $num ([$items->[2], $items->[3]]) {
        print "NUM: $num\n";
          my $is_between = (sort {$a <=> $b} $lower, $upper, $num)[1] == $num;

          printf "$num is%s between $lower and $upper\n", $is_between ? "" : " not";
      }
    }
  } elsif ($items->[0] eq q[exit] || $items->[0] eq q[quit]) {
    exit;
  } else {
    $args->{error} = qq[command should start with either "add" or "move"\n];
  }
  return $args;
}
