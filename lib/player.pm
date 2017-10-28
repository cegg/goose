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

our $rules = {a => 1};


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

=head1 NAME

The Game of the Goose

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 init - instantiate player object

=head2 create

=head2 move

=head2 position - returns current position of the user

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
