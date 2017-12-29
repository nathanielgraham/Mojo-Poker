# Mojo-Poker
Poker client and server built with the Mojolicious Framework.

## Features
The following 28 poker variants work out-of-the-box:
Dealer's Choice, Hold'em, Hold'em jokers wild, Pineapple, Crazy Pineapple, Omaha, Omaha Hi-Lo, 5 Card Omaha, 5 Card Omaha Hi-Lo, Courcheval, Courcheval Hi-Lo, 5 Card Draw, 5 Card Draw Deuces Wild, 2-7 Single Draw, 2-7 Triple Draw, A-5 Single Draw, A-5 Triple Draw, 7 Card Stud, 7 Card Stud Jokers Wild, 7 Card Stud Hi-Lo, Razz, High Chicago, Follow the Queen, The Bitch, Badugi, Badacey, Badeucy. 

See [SCREENSHOT.png](https://github.com/mojopoker/Mojo-Poker/blob/master/SCREENSHOT.png)

Another cool feature is the ability to create custom variants with minimal coding. For example, wildcards could be added to any of the above games. 

## Install
Tested on Ubuntu 16.04. Other distros might require tweaking.
Begin with a newly installed, "clean" install of Ubuntu 16.04.
As root, issue the following commands in your terminal session:

    cd /tmp
    wget https://github.com/mojopoker/Mojo-Poker/archive/master.zip
    unzip master.zip
    cd Mojo-Poker-master
    sudo ./install

## Starting the server
Issue the following command in your terminal session:

    sudo /opt/mojopoker/script/mojopoker.pl

Now point your browser at http://localhost

## Starting the server in production mode
Issue the following command in your terminal session:

    sudo /opt/mojopoker/script/mojopoker.pl -p

Now point your browser at https://localhost (forces https on port 80).
Remember to put cert and key files down /opt/mojopoker/ssl.

## Stopping the server

    sudo kill `cat mojopoker.pid`

## Loading games
wsshell.pl is a command-line utility for sending JSON encoded WebSocket messages to the server. To load a few example games, issue the following command in your terminal session:

    sudo /opt/mojopoker/script/wsshell.pl < /opt/mojopoker/db/example_games

Add the -p flag if the server is running in production mode.

## Admin
To enter the admin shell, issue the following command in your terminal: 

    sudo /opt/mojopoker/script/wsshell.pl 

Commands should be formatted as follows:

    [ "command" , { "arg1": "value", "arg2": "value" } ]

The shell recognizes the following commands and arguments:
 
* login 
  * username 
  * password 
* login_book
  * bookmark
* guest_login
* login_info  
* update_login  
  * username 
  * email  
  * birthday 
  * handle  
  * password
* logout
* block   
  * login_id
* unblock  
  * login_id 
* join_channel
  * channel
* unjoin_channel
  * channel 
* write_channel 
  * channel 
  * message
* ping
* credit_chips
  * user_id
  * login_id 
  * chips
* logout_all
* logout_user 
  * login_id
* create_channel 
  * channel 
* destroy_channel
  * channel
* update_news  
  * news

## Writing a bot
See [Poker::Robot](https://metacpan.org/pod/Poker::Robot) 

## TODO 
- [ ] Add support for tournaments
- [ ] Change hand evaluator to [Poker::Eval](https://metacpan.org/pod/Poker::Eval)

## COPYRIGHT AND LICENSE
Copyright (C) 2016, Nathaniel J. Graham

This program is free software, you can redistribute it and/or modify it
nder the terms of the Artistic License version 2.0.
https://dev.perl.org/licenses/artistic.html
