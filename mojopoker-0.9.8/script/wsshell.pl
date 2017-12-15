#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::UserAgent;
use AnyEvent::ReadLine::Gnu;
use EV;
use Getopt::Std;

our $opt_p;
getopts('p');

my $ua = Mojo::UserAgent->new(inactivity_timeout => 0);
my $ws = $opt_p ? 'wss://localhost:443/websocket' : 'ws://localhost:3000/websocket';

$ua->websocket(
  $ws => sub {
    my ( $ua, $tx ) = @_;

    unless ($tx->is_websocket) {
      AnyEvent::ReadLine::Gnu->print("WebSocket handshake failed! Try toggling the -p flag.\n");
      exit 0;
    }

    my $rl = new AnyEvent::ReadLine::Gnu
     prompt  => "$ws> ",
     on_line => sub {
      my $i = shift;
      exit 0 unless defined $i;
      exit 0 if $i && $i =~ /quit/i;
      if ( $i && !$tx->is_finished ) {
        $tx->send($i);
      }
    };

    $tx->on(
      finish => sub {
        my ( $tx, $code ) = @_;
        AnyEvent::ReadLine::Gnu->print("WebSocket closed with code $code.\n");
        exit 0;
      }
    );

    $tx->on(
      message => sub {
        my ( $tx, $msg ) = @_;
        return if $msg =~ /notify_lr_update/;
        AnyEvent::ReadLine::Gnu->print("server: $msg\n");
      }
    );
    $tx->send('["guest_login"]');

    # IMPORTANT: Admin login bookmark should be changed.   
    $tx->send('["login_book", {"bookmark":"dc17c0317495691235faf2ba1063278f08e2a524"}]');
  }
);

EV::run;

=head1 NAME

wsshell.pl - WebSocket Shell

=head1 VERSION

0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

This is a command line interface to the alice poker server. It establishes a websocket connection to the server and allows you to receive and send JSON encoded messages from the command line.  

=head1 PREREQUESITES

Mojo::UserAgent;
AnyEvent::ReadLine::Gnu;
EV;

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=head1 SCRIPT CATEGORIES

Networking

=cut
