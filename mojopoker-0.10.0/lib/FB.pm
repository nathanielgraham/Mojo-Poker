package FB;
use Moo;

with 'FB::Poker';

use feature qw(state);
use DBI;
use SQL::Abstract;
use Mojo::JSON qw(j);
use Digest::SHA qw(hmac_sha1_hex);
use FB::Poker;
use FB::Chat;
use FB::Login;
use FB::Login::WebSocket;

has 'cycle_event' => (
  is  => 'rw',
);

has 'news' => (
  is  => 'rw',
  isa => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { return [] },
);

has 'address_block' => (
  is  => 'rw',
  isa => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
);

has 'login_count' => (
  is      => 'rw',
  default => sub { return 0 },
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
  is  => 'rw',
  isa => sub { die "Not a SQL::Abstract!" unless $_[0]->isa('SQL::Abstract') },
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
    guest_login  => [ \&guest_login, { } ],
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
    credit_chips =>
      [ \&credit_chips, { user_id => 1, login_id => 0, chips => 1 }, 4 ],

   #    add_login_chips => [ \&add_login_chips, { login_id => 1, chips => 1 } ],
    logout_all => [ \&logout_all, {}, 4 ],
    logout_user     => [ \&logout_user,     { login_id => 1 }, 4 ],
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
    login_id => qr/^\d{1,12}$/,
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
  if ( $level && $login->level < $level ) {
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

  #print "REQTIME: " . $login->last_req_time . "ID: " . $login->id . "\n";
  #print Dumper([ keys $self->login_list ]);
  $self->command->{$cmd}->[0]( $self, $login, $opts );
}

sub _notify_login_watch {
  my ( $self, $msg ) = @_;
  for my $log ( values %{ $self->login_watch } ) {
    $log->send($msg);
  }
}

sub _fetch_login_opts {
  my ( $self, $login ) = @_;
  return {
    login_id       => $login->id,
    user_id        => $login->user_id,
    handle         => $login->handle,
    username       => $login->username,
    remote_address => $login->remote_address,
    last_visit     => $login->last_visit
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
      [ map { $self->_fetch_login_opts($_) } values %{ $self->login_list } ]
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
  $opts->{id}         = $self->login_count( $self->login_count + 1 );
  $opts->{last_visit} = time;
  $opts->{db}         = $self->db;
  return FB::Login::WebSocket->new($opts);
}

sub _guest_login {
  my ( $self, $opts ) = @_;
  my $login = $self->_new_login($opts);
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
        epoch    => $login->last_visit,
        chips    => $login->fetch_all_chips,
        invested => $login->fetch_all_invested,
        username => $login->username,
        news     => $self->news,
      }
    ]
  );
  $self->_notify_login_watch(
    [ 'notify_login', $self->_fetch_login_opts($login) ] );

  $self->_watch_logins($login);
  $self->_watch_lobby($login);
}

sub register {
  my ( $self, $login, $opts ) = @_;
  my $response = ['register_res'];
  if ( $login->user_id ) {
    $response->[1] = {
      success => 0,
      message => 'Already registered.',
      user_id => $login->user_id
    };
    $login->send($response);
    return;
  }
  $opts->{reg_date} = time;
  $opts->{level}    = 2;
  $opts->{handle}   = $opts->{username};
  my ( $stmt, @bind ) = $self->sql->insert( 'user', $opts );
  my $sth = $self->db->prepare($stmt);
  $sth->execute(@bind);
  if ( $self->db->err ) {
    $response->[1] = {
      success  => 0,
      username => $opts->{username},
      message  => 'username already taken.',
    };
    $login->send($response);
    return;
  }
  $opts->{user_id} = $self->db->last_insert_id( "", "", "", "" );

  # create bookmark
  $opts->{bookmark} = hmac_sha1_hex( $opts->{user_id}, $self->secret );

  # update user
  $self->_update_login( $login, $opts );
  my $tchips = $login->fetch_chips(1) + 2000;
  $login->credit_chips( 1, $tchips );
  $login->credit_invested( 1, $tchips );

  $response->[1] = { success => 1, %{ $self->_fetch_login_info($login) } };
  $login->send($response);
}

sub _update_user {
  my ( $self, $login, $opts ) = @_;
  $opts->{last_visit}     = time;
  $opts->{remote_address} = $login->websocket->remote_address
    if $login->websocket->is_websocket;

  #$self->user_map->{ $login->user_id } = $login;
  my ( $stmt, @bind ) =
    $self->sql->update( 'user', $opts, { user_id => $login->user_id } );
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
  if ( $login->has_user_id ) {

    #$self->user_map->{ $login->user_id } = $login;
    $self->user_map->{ $login->user_id } = $login->id;
    $self->_update_user( $login, $opts );
  }

  # my %login_detail = %{ $self->_fetch_login_opts($login) };
  # $self->_notify_login_watch(
  #   [
  #     'notify_update_login',
  #     {
  #       login_id => $login->id,
  #       map { $_ => $login_detail{$_} }
  #         grep { exists $opts->{$_} } keys %login_detail
  #     }
  #   ]
  # );
  return { success => 1, %$opts };
}

sub reload {
  my ( $self, $login ) = @_;
  my $login_info = $self->_fetch_login_info($login);
  my $inplay = 0;
  for my $v (values %{ $login_info->{ring_play } }) {
    $inplay += $v;
  }
  my $play_chips = $login_info->{chips}->{1} || 0;
  my $total = $inplay + $play_chips;

  if ($total < 2000) {
    $login->credit_chips( 1, 2000 - $total );
    $login->credit_invested( 1, 2000 - $total );
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

  #print Dumper ($self->_fetch_user_info($login));

  my $ring_map = {};
  for my $t ( map { $self->table_list->{$_} } keys %{ $login->ring_play } ) {
    $ring_map->{ $t->table_id } = 0;
    for my $c ( @{ $t->_find_chairs($login) } ) {
      $ring_map->{ $t->table_id } += $c->chips;
    }
  }
  return {
    %{ $self->_fetch_user_info($login) },
    login_id  => $login->id,
    block     => $login->block,
    chips     => $login->fetch_all_chips,
    invested  => $login->fetch_all_invested,
    ring_play => $ring_map,
    success   => 1,
  };
}

sub _fetch_user_info {
  my ( $self, $login ) = @_;
  return {
    user_id        => $login->user_id,
    username       => $login->username,
    bookmark       => $login->bookmark,
    level          => $login->level,
    remote_address => $login->remote_address,
    email          => $login->email,
    birthday       => $login->birthday,
    handle         => $login->handle,
    last_visit     => $login->last_visit,
  };
}

sub _login {
  my ( $self, $login, $opts ) = @_;

  my $response = [ 'login_res', { success => 1, login_id => $login->id } ];
  my $user_opts = $self->fetch_user_opts($opts);
  unless ( $user_opts && $user_opts->{user_id} ) {
    $response->[1]->{success} = 0;
    $response->[1]->{message} = 'Login failed.';
    $login->send($response);
    return;
  }

  if ( $login->user_id ) {
    $response->[1]->{success} = 0;
    $response->[1]->{message} = 'You are already logged in.';
    $login->send($response);
    return;
  }

  # reconnect

  my $old_login_id = delete $self->user_map->{ $user_opts->{user_id} };

  #if ( $self->user_map->{ $user_opts->{user_id} } ) {
  if ($old_login_id) {
    $self->_cleanup($login);

    #my $old_login = $self->user_map->{ $user_opts->{user_id} };
    #my $old_login = delete $self->login_list->{ $lid };
    my $old_login = delete $self->login_list->{$old_login_id};

    #delete $self->login_list->{ $self->user_map->{ $user_opts->{user_id} } };
    #$self->_cleanup($login);

    $old_login->send(
      [ 'forced_logout', { message => 'Another login has been detected.' } ] );
    $old_login->logout;
    $response->[1]->{message} = 'Reconnect.',

      $login->id( $old_login->id );

    #$login->user_id($old_login->user_id);
    $login->play_chips( $old_login->play_chips );
    $login->ring_play( $old_login->ring_play );
    $login->tour_play( $old_login->tour_play );
    $self->login_list->{ $login->id } = $login;

    #$self->_force_logout( $old_login,
    #  { message => 'Another login has been detected.' } );
    #$old_login->websocket( $login->websocket );
    #$self->_cleanup($login);
    #%$login = %$old_login;
    #$response->[1] = {
    #  success => 1,
    #  message => 'Reconnect.',
    #  %{ $self->_fetch_login_info($login) }
    #};
    #$login->send($response);
    #$self->_notify_login_watch(
    #  [ 'notify_login', $self->_fetch_login_opts($login) ] );
    #return;
  }

  %$login = ( %$login, %$user_opts );
  $self->user_map->{ $login->user_id } = $login->id;
  $response->[1] = {
    %{ $response->[1] },
    success => 1,
    %{ $self->_fetch_login_info($login) }
  };
  $login->send($response);
  $self->_notify_login_watch(
    [ 'notify_login', $self->_fetch_login_opts($login) ] );
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
  return $sth->fetchrow_hashref;
}

#sub _fetch_user_chips {
#  my ( $self, $login ) = @_;
#  my %chip;
#  my $sql = "SELECT director_id, chips FROM user_chips WHERE user_id = "
#    . $login->user_id;
#  my $sth = $self->db->prepare($sql);
#  $sth->execute;
#  while ( my ( $director_id, $chips ) = $sth->fetchrow_array ) {
#    $chip{$director_id} = $chips;
#  }
#  return {%chip};
#}

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
  $self->_cleanup($login);
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

sub _cleanup {
  my ( $self, $login ) = @_;

  # remove from login_list
  delete $self->login_list->{ $login->id };

  # remove from login_watch
  delete $self->login_watch->{ $login->id };

  # remove from user_map
  delete $self->user_map->{ $login->user_id } if $login->user_id;

  # remove from chat channels
  for my $channel ( values %{ $self->channels } ) {
    $channel->unjoin($login);
  }

  # poker cleanup
  $self->_poker_cleanup($login);

  if ( $login->has_user_id ) {

    # update user database
    $self->_update_user( $login, $self->_fetch_user_info($login) );

    # cashout: update user_chips
  }

  $self->_notify_login_watch(
    [ 'notify_logout', $self->_fetch_login_opts($login) ] );
}

sub block {
  my ( $self, $login, $opts ) = @_;
  my $response    = ['block_res'];
  my $block_login = $self->login_list->{ $opts->{login_id} };
  unless ($block_login) {
    $response->{success} = 0;
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
    [ 'destroy_channel_res', { success => 1, channel => $opts->{channel} } ] );
}

sub create_channel {
  my ( $self, $login, $opts ) = @_;
  $self->_create_channel($opts);
  $login->send(
    [ 'create_channel_res', { success => 1, channel => $opts->{channel} } ] );
}

sub _create_channel {
  my ( $self, $opts ) = @_;
  $self->channels->{ $opts->{channel} } = FB::Chat->new($opts);
}

sub join_channel {
  my ( $self, $login, $opts ) = @_;
  if ( !exists $self->channels->{ $opts->{channel} } ) {
    $login->send(
      [ 'join_channel_res', { success => 0, message => 'No such channel.' } ] );
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
      [ 'unjoin_channel_res', { success => 0, message => 'No such channel.' } ]
    );
    return;
  }
  $self->channels->{ $opts->{channel} }->unjoin($login);
  $login->send(
    [ 'unjoin_channel_res', { success => 1, channel => $opts->{channel} } ] );
}

sub write_channel {
  my ( $self, $login, $opts ) = @_;
  if ( !exists $self->channels->{ $opts->{channel} } ) {
    $login->send(
      [ 'write_channel_res', { success => 0, message => 'No such channel.' } ]
    );
    return;
  }
  $self->channels->{ $opts->{channel} }->write( $login->id, $opts );
  $login->send(
    [ 'write_channel_res', { success => 1, channel => $opts->{channel} } ] );
}

sub ping {
  my ( $self, $login ) = @_;
  $login->send( [ 'ping_res', { epoch => time } ] );
}

sub credit_chips {
  my ( $self, $login, $opts ) = @_;
  my $response = [ 'credit_chips_res', { success => 0 } ];

  my $temp_login = $self->_new_login( { user_id => $opts->{user_id} } );
  my $director_id = $login->user_id;
  $temp_login->credit_chips( $director_id, $opts->{chips} );

  if ( $self->db->err ) {
    $login->send($response);
    return;
  }

  my $login_id =
       $opts->{login_id}
    && $self->login_list->{ $opts->{login_id} } ? $opts->{login_id}
    : $self->user_map->{ $opts->{user_id} }
    ? $self->user_map->{ $opts->{user_id} }
    : undef;

  my $log = $self->login_list->{ $login_id } if $login_id;
  my $user_id = $log ? $log->user_id : undef;

  my $re = {
    chips       => $temp_login->fetch_chips($director_id),
    user_id     => $user_id,
    login_id    => $login_id,
    director_id => $director_id,
    success     => 1,
  };

  $response->[1] = $re;

  if ($log) {
    $log->send( [ 'notify_credit_chips', $re ] );
  }
  $login->send($response);
}

sub cycle300 {
  my $self = shift;
  my $now  = time;
  for my $login ( values %{ $self->login_list } ) {
    next if $login->remote_address eq '127.0.0.1';
    my $diff = $now - $login->last_req_time;
    #print "LOGIN: " . $login->id . " NOW: " . time . " VARNOW: $now" . "LASTREQ: " . $login->last_req_time . "DIFF: " . $diff . "\n";
    if ( $now - $login->last_req_time > $self->max_idle ) {
      $login->send( [ 'forced_logout', { message => 'Idle too long.' } ] );
      $self->_logout($login);
    }
  }
}

sub update_news {
  my ( $self, $login, $opts ) = @_;
  my $res = [ 'update_news_res', { success => 1 } ];
  if ( ref( $opts->{news} ) eq 'ARRAY' ) {
    $self->news( $opts->{news} );
  }
  else {
    $res->[1]->{success} = 0;
  }
  $login->send($res);
}

sub BUILD {
  my $self = shift;
  $self->db( $self->_build_db );
  $self->option( { %{ $self->option }, %{ $self->poker_option } } );
  $self->command( { %{ $self->command }, %{ $self->poker_command } } );
  #$self->cycle_event(EV::timer 300, 300, sub {
  #  $self->cycle300;
  #});
}

1;

