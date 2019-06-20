#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use lib '/opt/mojopoker/lib';
use Ships;
use EV;
use Mojo::Server::Daemon;
use POSIX qw(setsid);

$ENV{MOJO_MODE}               = 'production';
$ENV{MOJO_INACTIVITY_TIMEOUT} = 0;
$ENV{MOJO_LOG_LEVEL} = 'fatal';

my @listen = ('http://*:3000');

my $daemon = Mojo::Server::Daemon->new(
    app                => Ships->new,
    listen             => [@listen],
    accepts            => 0,
    proxy              => 1,
);


=pod
# Fork and kill parent
die "Can't fork: $!" unless defined( my $pid = fork );
exit 0 if $pid;
POSIX::setsid or die "Can't start a new session: $!";

# pid file
open my $handle, '>', 'mojopoker.pid';
print $handle $$;
close $handle;
=cut

# Close filehandles
open STDIN,  '</dev/null';
#open STDERR, '>./errors';
open STDERR, '>&STDOUT';

$daemon->start;

#open STDOUT, '>/dev/null';

EV::run;
