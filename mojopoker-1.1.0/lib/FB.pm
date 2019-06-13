package FB;
use Moo;

with 'FB::Poker';

use feature qw(state);
use DBI;
use SQL::Abstract;
use Mojo::JSON qw(j);
use Digest::SHA qw(hmac_sha1_hex hmac_sha256);
use FB::Poker;
use FB::Chat;
use FB::Login;
use FB::Login::WebSocket;
use FB::User;
use Time::Piece;
use Time::Seconds;
use MIME::Base64;
use Data::Dumper;

has 'cycle_event' => ( is => 'rw', );

has 'prize_timer' => (
    is      => 'rw',
    builder => '_build_prize_timer',
);

has 'facebook_secret' => ( is => 'rw', );

# reset timer
sub _build_prize_timer {
    my $self     = shift;
    my $t        = localtime;
    my $add_days = abs( ( 1 - $t->wday ) % 7 );

    #$add_days |= 7;
    $t += $add_days * 24 * 60 * 60;
    $t -= $t->sec;
    $t -= $t->min * 60;
    $t -= $t->hour * 60 * 60;

    # next Sunday
    my $seconds = $t - localtime;
    return EV::timer $seconds, 604800, sub {
        $self->prize_timer( $self->_build_prize_timer );
    };
}

has 'news' => (
    is      => 'rw',
    isa     => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
    default => sub { return [] },
);

has 'address_block' => (
    is  => 'rw',
    isa => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
);

has 'max_idle' => (
    is      => 'rw',
    default => sub { return 600 },
);

has 'secret' => (
    is      => 'rw',
    default => sub { return 'g)ue(ss# %m4e &i@f y25o*u c*69an' },
);

has 'start_time' => (
    is      => 'rw',
    default => sub { return time },
);

has 'sql' => (
    is => 'rw',
    isa =>
      sub { die "Not a SQL::Abstract!" unless $_[0]->isa('SQL::Abstract') },
    builder => '_build_sql',
);

sub _build_sql {
    my $self = shift;
    return SQL::Abstract->new;
}

has 'db' => ( is => 'rw', );

sub _build_db {
    my $self = shift;
    return DBI->connect( "dbi:SQLite:dbname=/opt/mojopoker/db/fb.db", "", "" );
}

has 'login_list' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_login_list',
);

sub _build_login_list {
    return {};
}

has 'login_watch' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_login_watch',
);

sub _build_login_watch {
    return {};
}

has 'user_map' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_user_map',
);

sub _build_user_map {
    return {};
}

has 'channels' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_channels',
);

sub _build_channels {
    return {};
}

has 'command' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_command',
);

sub _build_command {
    return {
        sys_info => [ \&sys_info, {} ],
        register => [
            \&register,
            {
                username => 0,
                password => 0,
                email    => 0,
                birthday => 0,
                handle   => 0
            }
        ],
        login_book => [ \&login_book, { bookmark => 1 } ],
        login      => [ \&login,      { username => 1, password => 1 } ],
        authorize  => [ \&authorize,  { status   => 1, authResponse => 1 } ],
        guest_login    => [ \&guest_login, {} ],
        watch_logins   => [ \&watch_logins ],
        unwatch_logins => [ \&unwatch_logins ],
        login_info     => [ \&login_info ],
        reload         => [ \&reload ],
        update_login   => [
            \&update_login,
            {
                username => 0,
                email    => 0,
                birthday => 0,
                handle   => 0,
                password => 0,
            }
        ],
        logout         => [ \&logout,         {} ],
        block          => [ \&block,          { login_id => 1 } ],
        unblock        => [ \&unblock,        { login_id => 1 } ],
        join_channel   => [ \&join_channel,   { channel => 1 } ],
        unjoin_channel => [ \&unjoin_channel, { channel => 1 } ],
        write_channel  => [ \&write_channel,  { channel => 1, message => 1 } ],
        ping           => [ \&ping,           {} ],

        # ADMIN
        credit_chips => [ \&credit_chips, { user_id => 1, chips => 1 }, 4 ],

   #    add_login_chips => [ \&add_login_chips, { login_id => 1, chips => 1 } ],
        logout_all => [ \&logout_all, {}, 4 ],
        logout_login    => [ \&logout_login,    { login_id => 1 }, 4 ],
        logout_user     => [ \&logout_user,     { user_id  => 1 }, 4 ],
        create_channel  => [ \&create_channel,  { channel  => 1 }, 4 ],
        destroy_channel => [ \&destroy_channel, { channel  => 1 }, 4 ],
        update_news     => [ \&update_news,     { news     => 1 }, 4 ],
    };
}

has 'option' => (
    is      => 'rw',
    isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
    builder => '_build_option',
);

sub _build_option {
    return {
        username => qr/^[a-zA-Z0-9\s!@#\$%^&\*\(\)_]{2,20}$/,
        password => qr/^[a-zA-Z0-9\s!@#\$%^&\*\(\)_]{2,20}$/,
        handle   => qr/^[a-zA-Z0-9\s!@#\$%^&\*\(\)_]{2,20}$/,
        channel  => qr/^[\w\s_]{1,20}$/,
        message  => qr/^[\w\s\.\,\?!@#\$%^&\*\(\)_]{2,80}$/,
        email    => qr/^\w{2,20}@\w{2,20}\.\w{3,8}/,
        birthday => qr/^[\w\s_\.\\\-]{40}$/,
        bookmark => qr/^\w{40}$/,
        bitcoin  => qr/^\w{52}$/,

        #login_id => qr/^\d{1,12}$/,
        user_id  => qr/^\d{1,12}$/,
        table_id => qr/^\d{1,12}$/,
    };
}

sub validate {

    my ( $self, $cmd, $opts ) = @_;

    # missing required param
    my $valid = $self->command->{$cmd}->[1];
    for ( keys %$valid ) {
        if ( $valid->{$_} && !defined $opts->{$_} ) {
            return { error => 'missing_option', command => $cmd, option => $_ };
        }
    }

    # invalid key or value
    while ( my ( $key, $value ) = each %$opts ) {
        if ( exists $valid->{$key} && defined $value ) {
            if ( ref $self->option->{$key} eq 'Regexp'
                && $value !~ $self->option->{$key} )
            {
                return {
                    error   => 'invalid_value',
                    command => $cmd,
                    option  => $key
                };
            }
            elsif ( ref $self->option->{$key} eq 'CODE'
                && !$self->option->{$key}($value) )
            {
                return {
                    error   => 'invalid_value',
                    command => $cmd,
                    option  => $key
                };
            }
        }
        else {
            return {
                error   => 'invalid_option',
                command => $cmd,
                option  => $key
            };
        }
    }

    # hash password
    $opts->{password} = hmac_sha1_hex( $opts->{password}, $self->secret )
      if $opts->{password};

    return $opts;
}

sub request {
    my ( $self, $login, $aref ) = @_;

    #my ( $self, $login, $json ) = @_;

    #my $aref = eval { decode_json ref $json ? $$json : $json };
    #if ($@) {
    #  $login->req_error;
    #  $login->send( [ 'malformed_json', { message => $@ } ] );
    #  return;
    #}

    if ( ref $aref ne 'ARRAY' ) {
        $login->req_error;
        $login->send( ['invalid_command_format'] );
        return;
    }

    my ( $cmd, $opts ) = @$aref;

    if ( ref $cmd || !exists $self->command->{$cmd} ) {
        $login->req_error;
        $login->send( ['invalid_command'] );
        return;
    }

    my $level = $self->command->{$cmd}->[2];
    if ( $level && $login->user->level < $level ) {
        $login->req_error;
        $login->send( [ 'permission_denied', { command => $cmd } ] );
        return;
    }

    if ( $opts && ref $opts ne 'HASH' ) {
        $login->req_error;
        $login->send( [ 'invalid_option_format', { command => $cmd } ] );
        return;
    }

    $opts = $self->validate( $cmd, $opts );
    if ( $opts->{error} ) {
        $login->req_error;
        $login->send( [ 'invalid_option', $opts ] );
        return;
    }

    $login->last_req_time(time);

    $self->command->{$cmd}->[0]( $self, $login, $opts );
}

#sub _notify_login_watch {
#    my ( $self, $msg ) = @_;
#    for my $log ( values %{ $self->login_watch } ) {
#        $log->send($msg);
#    }
#}

sub _notify_logins {
    my $self        = shift;
    my $login_count = keys %{ $self->login_list };
    for my $log ( values %{ $self->login_list } ) {
        $log->send( [ 'notify_logins', { login_count => $login_count } ] );
    }
}

sub _fetch_login_opts {
    my ( $self, $login ) = @_;
    return {
        login_id       => $login->id,
        user_id        => $login->user->id,
        remote_address => $login->remote_address,
    };
}

sub watch_logins {
    my ( $self, $login ) = @_;
    $login->send( [ 'watch_logins_res', { success => 1 } ] );
    $self->_watch_logins($login);
}

sub _watch_logins {
    my ( $self, $login ) = @_;
    $self->login_watch->{ $login->id } = $login;
    $self->_login_snap($login);
}

sub unwatch_logins {
    my ( $self, $login ) = @_;
    $self->_unwatch_logins($login);
    $login->send( [ 'unwatch_logins_res', { success => 1 } ] );
}

sub _unwatch_logins {
    my ( $self, $login ) = @_;
    delete $self->login_watch->{ $login->id };
}

sub _login_snap {
    my ( $self, $login ) = @_;
    $login->send(
        [
            'login_snap',
            [
                map { $self->_fetch_login_opts($_) }
                  values %{ $self->login_list }
            ]
        ]
    );
}

sub sys_info {
    my ( $self, $login ) = @_;
    my $now = time;
    $login->send(
        [
            'sys_info_res',
            {
                epoch      => $now,
                uptime     => ( $now - $self->start_time )->pretty,
                login_list => scalar keys %{ $self->login_list },
            }
        ]
    );
}

sub _new_login {
    my ( $self, $opts ) = @_;
    my $connection_id = $opts->{websocket}->connection;
    return unless $connection_id;
    $opts->{id}         = $connection_id;
    $opts->{last_visit} = time;
    #$opts->{db}         = $self->db;
    return FB::Login::WebSocket->new($opts);
}

sub _guest_login {
    my ( $self, $opts ) = @_;
    my $login = $self->_new_login($opts);
    return unless $login;
    $self->join_channel( $login, { channel => 'main' } );

    #$login->credit_chips( 1, 2000 );
    #$self->login_list->{ $login->id } = $login;
    return $login;
}

sub guest_login {
    my ( $self, $login ) = @_;

    #$login->timeout(EV::timer 10, 0, sub { $self->logout($login) });
    #$login->credit_chips( 1, 2000 );
    #$login->credit_invested( 1, 2000 );
    $self->login_list->{ $login->id } = $login;
    $login->send(
        [
            'guest_login',
            {
                login_id => $login->id,
                timer    => int( $self->prize_timer->remaining ),
            }
        ]
    );

    #    $self->_notify_login_watch(
    #        [ 'notify_login', $self->_fetch_login_opts($login) ] );

    #    $self->_watch_logins($login);
    $self->_watch_lobby($login);
    $self->_notify_logins();
    $login->send( [ 'notify_leaders', { leaders => $self->_fetch_leaders } ] );
}

sub register {
    my ( $self, $login, $opts ) = @_;
    my $response = ['register_res'];
    if ( $login->has_user ) {
        $response->[1] = {
            success => 0,
            message => 'Already registered.',
            user_id => $login->user->id
        };
        $login->send($response);
        return;
    }
    $opts->{reg_date} = time;
    $opts->{level}    = 2;
    $opts->{handle}   = $opts->{username} if $opts->{username};
    my ( $stmt, @bind ) = $self->sql->insert( 'user', $opts );
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
    if ( $self->db->err ) {
        $response->[1] = {
            success  => 0,
            username => $opts->{username},
            message  => 'username already taken ... or something.',
        };
        $login->send($response);
        return;
    }
    $opts->{id} = $self->db->last_insert_id( "", "", "", "" );

    # create bookmark
    $opts->{bookmark} = hmac_sha1_hex( $opts->{id}, $self->secret );

    # db handle
    #$opts->{db}         = $self->db;

    # add user
    $login->user( FB::User->new(%$opts) );
    $self->user_map->{ $login->user->id } = $login->id;
    $login->user->db( $self->db );

    # update user
    $self->_update_user( $login, $opts );
    $self->_credit_chips( $login->user->id, 2000);
    $self->_credit_invested( $login->user->id, 2000);
    $response->[1] = { success => 1, %{ $self->_fetch_login_info($login) } };
    $login->send($response);
}

sub _update_user {

    my ( $self, $login, $opts ) = @_;
    $opts->{last_visit} = time;

    #$opts->{remote_address} = $login->websocket->remote_address
    #  if $login->websocket->is_websocket;

    #print Dumper($opts);
    my ( $stmt, @bind ) =
      $self->sql->update( 'user', $opts, { id => $opts->{id} } );
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);

}

sub update_login {
    my ( $self, $login, $opts ) = @_;
    my $response = ['update_login_res'];
    $response->[1] = $self->_update_login( $login, $opts );
    $login->send($response);
}

sub _update_login {
    my ( $self, $login, $opts ) = @_;
    %$login = ( %$login, %$opts );

    #if ( $login->has_user ) {
    #    $self->user_map->{ $login->user->id } = $login->id;
    #    $self->_update_user( $login, $opts );
    #}
    return { success => 1, %$opts };
}

sub reload {

    my ( $self, $login ) = @_;
    my $login_info = $self->_fetch_login_info($login);
    my $inplay     = 0;
    for my $v ( values %{ $login_info->{ring_play} } ) {
        $inplay += $v;
    }
    my $chips = $login_info->fetch_chips;
    my $total = $inplay + $chips;

    if ( $total < 2000 ) {
        $self->_credit_chips( $login->user->id, 2000 - $total );
        $self->_credit_invested( $login->user->id, 2000 - $total );
    }
    $self->login_info($login);
}

sub login_info {
    my ( $self, $login ) = @_;
    my $response = ['login_info_res'];
    $response->[1] = $self->_fetch_login_info($login);
    $login->send($response);
}

sub _fetch_login_info {
    my ( $self, $login ) = @_;

    my $ring_map = {};
    for my $t ( map { $self->table_list->{$_} }
        keys %{ $login->user->ring_play } )
    {
        $ring_map->{ $t->table_id } = 0;
        for my $c ( @{ $t->_find_chairs($login) } ) {
            $ring_map->{ $t->table_id } += $c->chips;
        }
    }
    return {
        %{ $self->_fetch_user_info($login) },
        login_id  => $login->id,
        ring_play => $ring_map,
        success   => 1,
    };
}

sub _fetch_user_info {
    my ( $self, $login ) = @_;
    return unless $login->has_user;
    my $chips = $self->_fetch_chips( $login->user->id );
    return {
        id          => $login->user->id,
        facebook_id => $login->user->facebook_id,
        username    => $login->user->username,
        bookmark    => $login->user->bookmark,
        level       => $login->user->level,
        email       => $login->user->email,
        birthday    => $login->user->birthday,
        handle      => $login->user->handle,
        chips       => $chips,
        last_visit  => $login->user->last_visit,
    };
}

sub authorize {
    my ( $self, $login, $opts ) = @_;

    #my $secret = 'dee98631a540b933dd8e2f46e1ab9512';
    my $secret = $self->facebook_secret;
    my $signed = $opts->{authResponse}->{signedRequest};
    my ( $encoded_sig, $payload ) = split( /\./, $signed, 2 );
    my $data         = j( decode_base64($payload) );
    my $response     = [ 'authorize_res', { success => 0 } ];
    my $expected_sig = encode_base64( hmac_sha256( $payload, $secret ), "" );
    $expected_sig =~ tr/\/+/_-/;
    $expected_sig =~ s/=//;

    if ( $encoded_sig eq $expected_sig ) {

        # signature verified
        $response->[1] = { success => 1 };

        $opts->{facebook_id} = $data->{user_id};
        $opts->{username}    = $data->{user_id};

    }

    $login->send($response);

    # return unless authorized
    return unless $response->[1]->{success};
    my $user_opts =
      $self->fetch_user_opts( { facebook_id => $opts->{facebook_id} } );

    #$login->send(["authorize_res", { user_opts => $user_opts }]);

    # already registered, so login
    if ( $user_opts && $user_opts->{id} ) {
        $login->send( [ "authorize_res", { msg => 'already registerd' } ] );
        $self->_login( $login,
            { id => $user_opts->{id} } );
    }

    # register new user
    else {
        $login->send( [ "authorize_res", { msg => 'register' } ] );
        my $un = 'user' . $opts->{facebook_id};
        $self->register( $login,
            { facebook_id => $opts->{facebook_id}, username => $un } );
    }
}

sub _login {
    my ( $self, $login, $opts ) = @_;

    my $response = [ 'login_res', { login_id => $login->id } ];

    my $user_opts = $self->fetch_user_opts($opts);

    #$login->send(["authorize_res", { mango => $user_opts}]);
    unless ( $user_opts && $user_opts->{user_id} ) {
        $response->[1]->{success} = 0;
        $response->[1]->{message} = 'Login failed.';
        $login->send($response);
        return;
    }

    if ( $user_opts->{user_id} == 1 ) {
        unless ( $login->remote_address eq '127.0.0.1' ) {
            $response->[1]->{success} = 0;
            $response->[1]->{message} = 'No remote admin access.';
            $login->send($response);
            return;
        }
    }

    if ( $login->has_user ) {
        $response->[1]->{success} = 0;
        $response->[1]->{message} = 'You are already logged in.';
        $login->send($response);
        return;
    }

    #$login->user(FB::User->new(%$user_opts));
    #$self->user_map->{ $login->user->id } = $login->id;

    # logout any old connections
    my $old_login_id = $self->user_map->{ $user_opts->{user_id} };
    my $old_login = $self->login_list->{$old_login_id} if $old_login_id;

    if ( $old_login && ref($old_login) ) {
        $old_login->send(
            [
                'forced_logout',
                { message => 'Another login has been detected.' }
            ]
        );

        #$self->_cleanup($old_login);
        $old_login->logout;
    }

    # %$login = ( %$login, %$user_opts );
    $login->user( FB::User->new(%$user_opts) );
    $self->user_map->{ $login->user->id } = $login->id;
    $login->user->db( $self->db );

    #print Dumper($self->user_map);

    $response->[1] = {
        %{ $response->[1] },
        success => 1,
        %{ $self->_fetch_login_info($login) }
    };
    $login->send($response);

    #$self->_notify_logins();
    #$login->send(['notify_leaders', { leaders => $self->_fetch_leaders }]);

## Please see file perltidy.ERR
    # $self->join_channel($login, {channel => 'main'});
    # $self->_notify_login_watch(
    #    [ 'notify_login', $self->_fetch_login_opts($login) ] );
}

#sub _force_logout {
#  my ( $self, $login, $opts ) = @_;
#  $login->send( [ 'forced_logout', $opts ] );
#  $login->logout;
#}

sub login {
    my ( $self, $login, $opts ) = @_;
    $self->_login( $login, $opts, { username => 1, password => 1 } );
}

sub login_book {
    my ( $self, $login, $opts ) = @_;
    $self->_login( $login, $opts, { bookmark => 1 } );
}

sub fetch_user_opts {
    my ( $self, $opts ) = @_;
    my ( $stmt, @bind ) = $self->sql->select( 'user', '*', $opts );
    my $sth = $self->db->prepare($stmt);
    $sth->execute(@bind);
    my $href = $sth->fetchrow_hashref;
    $href->{user_id} = $href->{id};
    return $href;
}

sub _fetch_leaders {
    my $self = shift;
    my $sql  = <<SQL;
SELECT username, ROUND((chips*1.0/invested),3) AS rating 
FROM user
ORDER BY rating DESC
SQL

    my $ary_ref = $self->db->selectall_arrayref($sql);
    return $ary_ref;
}

sub _notify_leaders {
    my $self    = shift;
    my $leaders = $self->_fetch_leaders;

    my $login_count = keys %{ $self->login_list };

    my $response = [
        'notify_leaders',
        {
            logins  => $login_count,
            leaders => $leaders,
            success => 1,
        }
    ];

    for my $log ( values %{ $self->login_list } ) {
        $log->send($response);
    }
}

sub logout {
    my ( $self, $login ) = @_;
    my $response = [ 'logout_res', { success => 1 } ];
    $login->send($response);
    $self->_logout($login);

    #  $self->_cleanup($login) if $login->has_user_id;
    #  $login->logout unless $login->websocket->is_finished;
}

sub _logout {
    my ( $self, $login ) = @_;

    #$self->_cleanup($login);
    $login->logout unless $login->websocket->is_finished;
}

sub logout_all {
    my ( $self, $login ) = @_;
    my $response = ['logout_all_res'];
    for my $log ( values %{ $self->login_list } ) {
        $self->_logout($log);
    }
}

sub logout_user {
    my ( $self, $login, $opts ) = @_;
    my $response = [ 'logout_user_res', { success => 1 } ];
    my $log = $self->login_list->{ $opts->{login_id} };
    $self->_logout($log);
    $login->send($response);
}

sub _debit_chips {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET chips = chips - $chips 
WHERE id = $user_id
SQL
    return $self->db->do($sql);
}

sub _credit_chips {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET chips = chips + $chips 
WHERE id = $user_id 
SQL
    return $self->db->do($sql);
}

sub _fetch_chips {
    my ( $self, $user_id ) = @_;
    my $sql = <<SQL;
SELECT chips 
FROM user 
WHERE id = ?
SQL

  my $sth = $self->db->prepare($sql);
  $sth->execute( $user_id );
  my $chips = $sth->fetchrow_array || 0;
  return $chips;
}

sub _credit_invested {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET invested = invested + $chips
WHERE id = $user_id 
SQL
    return $self->db->do($sql);
}

sub _cleanup {
    my ( $self, $login ) = @_;

    # poker cleanup
    $self->_poker_cleanup($login);

    # remove from login_list
    delete $self->login_list->{ $login->id };

    # remove from login_watch
    delete $self->login_watch->{ $login->id };

    # remove from chat channels
    for my $channel ( values %{ $self->channels } ) {
        $channel->unjoin($login);
    }

    if ( $login->has_user ) {

        # remove from user_map
        if ( $self->user_map->{ $login->user->id } eq $login->id ) {
            delete $self->user_map->{ $login->user->id };
        }

        # update user database
        $self->_update_user( $login, $self->_fetch_user_info($login) );

        # cashout: update user_chips
    }

    $self->_notify_logins();

}

sub block {
    my ( $self, $login, $opts ) = @_;
    my $response    = ['block_res'];
    my $block_login = $self->login_list->{ $opts->{login_id} };
    unless ($block_login) {
        $response->[1]->{success} = 0;
        $login->send($response);
    }
    $self->login->block->{ $opts->{login_id} } = 1;
    $response->[1] = $self->_fetch_login_opts($block_login);
    $response->[1]->{success} = 1;
    $login->send($response);
}

sub unblock {
    my ( $self, $login, $opts ) = @_;
    my $response    = ['unblock_res'];
    my $block_login = $self->login_list->{ $opts->{login_id} };
    unless ($block_login) {
        $response->{success} = 0;
        $login->send($response);
    }
    delete $self->login->block->{ $opts->{login_id} };
    $response->[1] = $self->_fetch_login_opts($block_login);
    $response->[1]->{success} = 1;
    $login->send($response);
}

sub destroy_channel {
    my ( $self, $login, $opts ) = @_;
    delete $self->channels->{ $opts->{channel} };
    $login->send(
        [
            'destroy_channel_res', { success => 1, channel => $opts->{channel} }
        ]
    );
}

sub create_channel {
    my ( $self, $login, $opts ) = @_;
    $self->_create_channel($opts);
    $login->send(
        [ 'create_channel_res', { success => 1, channel => $opts->{channel} } ]
    );
}

sub _create_channel {
    my ( $self, $opts ) = @_;
    $self->channels->{ $opts->{channel} } = FB::Chat->new($opts);
}

sub join_channel {
    my ( $self, $login, $opts ) = @_;
    if ( !exists $self->channels->{ $opts->{channel} } ) {
        $login->send(
            [
                'join_channel_res',
                { success => 0, message => 'No such channel.' }
            ]
        );
        return;
    }
    $self->channels->{ $opts->{channel} }->join($login);
    $login->send(
        [ 'join_channel_res', { success => 1, channel => $opts->{channel} } ] );
    $login->send( $self->channels->{ $opts->{channel} }->refresh );
}

sub unjoin_channel {
    my ( $self, $login, $opts ) = @_;
    if ( !exists $self->channels->{ $opts->{channel} } ) {
        $login->send(
            [
                'unjoin_channel_res',
                { success => 0, message => 'No such channel.' }
            ]
        );
        return;
    }
    $self->channels->{ $opts->{channel} }->unjoin($login);
    $login->send(
        [ 'unjoin_channel_res', { success => 1, channel => $opts->{channel} } ]
    );
}

sub write_channel {
    my ( $self, $login, $opts ) = @_;
    if ( !exists $self->channels->{ $opts->{channel} } ) {
        $login->send(
            [
                'write_channel_res',
                { success => 0, message => 'No such channel.' }
            ]
        );
        return;
    }
    $self->channels->{ $opts->{channel} }->write( $login->id, $opts );
    $login->send(
        [ 'write_channel_res', { success => 1, channel => $opts->{channel} } ]
    );
}

sub ping {
    my ( $self, $login ) = @_;
    $login->send( [ 'ping_res', { epoch => time } ] );
}

sub credit_chips {
    my ( $self, $login, $opts ) = @_;
    my $response = [ 'credit_chips_res', { success => 0 } ];

    #my $login_id = $self->user_map->{ $opts->{user_id} };

=pod
    if (exists($self->user_map->{ $opts->{user_id} })) {
       my $log = $self->login_list->{ $opts->{user_id} };
       my $c = $log->credit_chips($opts->{chips});
       $response->[1]->{success} = 1;
       $response->[1]->{chips} = $c;
    }
=cut

    $login->send($response);
}

sub cycle300 {
    my $self = shift;
    $self->_notify_leaders();
}

sub BUILD {
    my $self = shift;
    $self->db( $self->_build_db );
    $self->option( { %{ $self->option }, %{ $self->poker_option } } );
    $self->command( { %{ $self->command }, %{ $self->poker_command } } );
    $self->_create_channel( { channel => 'main' } );
    $self->cycle_event(
        EV::timer 300,
        300,
        sub {
            $self->cycle300;
        }
    );
}

1;

