#!/usr/bin/env perl
use Poker::Robot::Random;
use strict;
use warnings;

my $table = shift @ARGV;

die "You must specify a table number as the first argument.\n"
  unless $table && $table =~ /\d+/;

# Bender makes legal but random moves

my $robot = Poker::Robot::Random->new(
    websocket => 'ws://0.0.0.0:3000/websocket',
    username  => 'Bender',
    ring_ids  => [$table],
);

$robot->connect;

