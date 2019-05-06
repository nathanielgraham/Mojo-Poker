#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::UserAgent;
use EV;
use feature qw(say);
use Getopt::Long;
use Mojo::JSON qw(j);

# options
my %opt = ();

GetOptions(
    \%opt,           'auto_start=i',  'ante=i',      'big_blind=i',
    'chair_count=i', 'channel=i',     'fix_limit=i', 'game_class=s',
    'limit=i',       'login_id=i',    'news=s',      'pot_cap=i',
    'small_bet=i',   'small_blind=i', 'table_id=i',  'table_min=i',
    'time_bank=i',   'turn_clock=i',  'help'
);

my $cmd = shift @ARGV;

if (!$cmd or $cmd =~ /help/i or exists $opt{'help'} ) {
   say help();
   exit 0;
}

my $ua = Mojo::UserAgent->new( inactivity_timeout => 0 );
my $ws = 'ws://0.0.0.0:3000/websocket';

$ua->websocket(
    $ws => sub {
        my ( $ua, $tx ) = @_;

        unless ( $tx->is_websocket ) {
            say("WebSocket handshake failed!\n");
            exit 0;
        }

        $tx->on(
            finish => sub {
                my ( $tx, $code ) = @_;
                say("WebSocket closed with code $code.\n");
                $tx->finish;
            }
        );

        $tx->on(
            message => sub {
                my ( $tx, $msg ) = @_;
                return if $msg =~ /notify_lr_update/;
                say("$msg\n");
            }
        );

        $tx->send('["guest_login"]');
        $tx->send(
'["login_book", {"bookmark":"dc17c0317495691235faf2ba1063278f08e2a524"}]'
        );
        $tx->send( j [ $cmd, \%opt ] );
        $tx->send('["logout"]');
    }
);

sub help {
    return <<EOT;
Usage:
mpadmin.pl <command> [<options>]

COMMANDS
    create_ring        Create a new ring game 
    destroy_ring       Delete a ring game  
    logout_user        Logout user
    logout_all         Logout all users
    credit_chips       Give chips to a user
    create_channel     Create a new chat room
    destroy_channel    Delete a chat room
    update_news        Change news items

OPTIONS 
    ante               Opening ante 
    big_blind          Big blind bet size
    chair_count        Number of seats (can be 2, 6, or 9)
    channel            Chat channel name
    fix_limit          Maximum bet in fixed limit game
    game_class         Game types: dealers, holdem, holdemjokers, omaha, omahahilo, badugi, crazypine, omahafive, omahafivehilo, courcheval, courchevalhilo, fivedraw, singledraw27, tripledraw27, badacey, badeucy, singledrawa5, tripledrawa5, pineapple, drawjokers, drawdeuces
    limit              Type of bet limit: NL, PL, FL 
    login_id           Login id of user
    news               List of front page news items 
    pot_cap            Maximum size of pot
    small_bet          Minimum bet in fixed limit game
    small_blind        Small blind bet size
    table_id           Id of ring game
    table_min          Minimum chips required to join game
    time_bank          Extra time if player exceeds turn clock
    turn_clock         Seconds per turn

EXAMPLE
    # Create a new Heads-Up Pot-Limit Omaha table
    mpadmin.pl create_ring -game_class omaha -limit PL -chair_count 2

EOT
}

EV::run;

=head1 NAME

mpadmin.pl - Mojo Poker admin tool

=head1 VERSION

0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

Mojo Poker admin tool   

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=cut
