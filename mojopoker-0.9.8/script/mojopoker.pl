#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);
use lib '/opt/mojopoker/lib';
use Ships;
use EV;
use Mojo::Server::Daemon;
use POSIX qw(setsid);
use Getopt::Std;

our $opt_p;
my @listen = ('http://*:80');
getopts('p');

# PRODUCTION MODE OPTION
if ($opt_p) {
    $ENV{MOJO_MODE} = 'production';
    push @listen, 'https://*:443?cert=/opt/mojopoker/ssl/server.crt&key=/opt/mojopoker/ssl/server.key';
}

my $daemon = Mojo::Server::Daemon->new(
    app                => Ships->new,
    listen             => [@listen],
    accepts            => 0,
    inactivity_timeout => 0,
);

# Fork and kill parent
die "Can't fork: $!" unless defined( my $pid = fork );
exit 0 if $pid;
POSIX::setsid or die "Can't start a new session: $!";

# pid file
open my $handle, '>', 'mojopoker.pid';
print $handle $$;
close $handle;

# Close filehandles
open STDIN,  '</dev/null';
open STDERR, '>&STDOUT';

$daemon->start;

if ($opt_p) {
    say 'Running in production mode!';
    say
'Remember to put cert and key files down /opt/mojopoker/ssl.';
}

open STDOUT, '>/dev/null';

EV::run;
