# Mojo-Poker
Poker Client and Server built with the Mojolicious Framework.
Tested on Ubuntu 16.04.

## Install
As root, issue the following commands in your terminal session:

    cd /tmp
    wget https://github.com/mojopoker/Mojo-Poker/archive/master.zip
    unzip master.zip
    cd Mojo-Poker-master
    sudo ./install

## Starting the server
Issue the following command in your terminal session:

    sudo /usr/local/share/mojopoker/script/mojopoker.pl

Now point your browser at http://localhost:3000

## Starting the server in production mode
Issue the following command in your terminal session:

    sudo /usr/local/share/mojopoker/script/mojopoker.pl -p

Now point your browser at https://localhost (forces https on port 80)

## Stopping the server

    sudo kill `cat mojopoker.pid`

## Loading games
wssshell.pl is a command-line utility for sending JSON encoded WebSocket messages to the server. To load a few sample games, issue the following command in your terminal session:

    sudo /usr/local/share/mojopoker/script/wsshell.pl < /usr/local/share/mojopoker/db/example_games

If the server is running in production mode, just add the -p flag:

    sudo /usr/local/share/mojopoker/script/wsshell.pl -p < /usr/local/share/mojopoker/db/example_games

## Admin
To enter the admin shell: 

    sudo /usr/local/share/mojopoker/script/wsshell.pl 

## COPYRIGHT AND LICENSE
Copyright (C) 2016, Nathaniel J. Graham

This program is free software, you can redistribute it and/or modify it
nder the terms of the Artistic License version 2.0.
https://dev.perl.org/licenses/artistic.html
