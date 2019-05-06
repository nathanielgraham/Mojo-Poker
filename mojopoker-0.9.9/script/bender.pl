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

# Fork and kill parent
die "Can't fork: $!" unless defined( my $pid = fork );
exit 0 if $pid;
POSIX::setsid or die "Can't start a new session: $!";

# pid file
open my $handle, '>', 'bender.pid';
print $handle $$;
close $handle;

# Close filehandles
open STDIN,  '</dev/null';
open STDERR, '>&STDOUT';

$robot->connect;

open STDOUT, '>/dev/null';

