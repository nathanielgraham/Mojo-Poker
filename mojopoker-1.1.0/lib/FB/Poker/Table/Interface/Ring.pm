package FB::Poker::Table::Interface::Ring;
use Moo::Role;

with 'FB::Poker::Table::Interface';

sub _build_type {
  return 'r';
}

has 'rake' => ( is => 'rw', );

has 'table_min' => (
  is      => 'rw',
  clearer => 1,
);

sub _build_table_min {
  my $self = shift;
  return ( ( $self->big_blind ? $self->big_blind : $self->small_bet ) * 20 );
}

has 'table_max' => (
  is      => 'rw',
  clearer => 1,
);

sub _build_table_max {
  my $self = shift;
  return ( ( $self->big_blind ? $self->big_blind : $self->small_bet ) * 100 );
}

has 'wait_list' => (
  is      => 'rw',
  isa     => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_wait_list',
);

sub _build_wait_list {
  return {};
}

sub _build_auto_start {
  my $self = shift;
  return $self->hydra_flag ? $self->chair_count : 2;
  #return 2;
}

around '_unseat_chair' => sub {
  my ( $orig, $self, $chair, $login ) = @_;
  my $chips = $chair->player->chips;
  my $r = $orig->( $self, $chair, $login );
  if ($r) {
    $login->credit_chips( $self->director_id, $chips );
    delete $login->ring_play->{ $self->table_id };
    $login->send( [ 'login_update', { chips => $login->fetch_all_chips } ] ) unless $login->websocket->is_finished;
    $self->_lobby_plr_update;
  }
  return 1;
};

around '_watch' => sub {
  my ( $orig, $self, $login ) = @_;
  my $r = $orig->( $self, $login );
  if ($r) {
    return {
      %$r,
      table_min => $self->table_min,
      table_max => $self->table_max,
    };
  }
};

around 'join' => sub {

  my ( $orig, $self, $login, $opts ) = @_;
  #my $r = $orig->( $self, $login, $cid, $player );
  my $r = $orig->( $self, $login, $opts );
  return $r unless $r->{success};

  my @chairs = @{ $self->_find_chairs_ip($login) };
  if ( scalar @chairs ) {

    #$response->[1] = {
    #  success => 0,
    #  message =>
    #    'Someone with your IP address is already seated at this table.',
    #  %$opts
    #};
    #$login->send($response);
    #return;
  }

  $opts->{chips} |= 0;
  $opts->{chips} = $self->table_max
    if ( $self->table_max && $opts->{chips} > $self->table_max );
  if ( $self->table_min && $opts->{chips} < $self->table_min ) {
    $r->{success}   = 0;
    $r->{message}   = 'Table minimum not met.';
    $r->{table_min} = $self->table_min;
    return $r;
  }

  my $balance = $login->fetch_chips( $self->director_id ) || 0;
  my $debit = $r->{hydra_chips} || $opts->{chips};
  
  if ( $balance < $debit ) {
    $r->{success} = 0;
    $r->{message} = 'Not enough chips.';
    $r->{balance} = $balance;
    return $r;
  }

  my $player = FB::Poker::Player->new( %$opts, login => $login );

  #if ($r->{hydra_chairs}) {
  if ($self->{hydra_flag}) {
    $player->wait_bb(0);
    for my $c (@{ $r->{hydra_chairs} }) {
      $self->sit( $c, $player->clone );
    }
  }
  else {
    $self->sit( $r->{chair}, $player );
  }

  $login->debit_chips( $self->director_id, $debit );
  $login->ring_play->{ $self->table_id } |= 0;
  $login->ring_play->{ $self->table_id }++;
  $login->send( [ 'login_update', { chips => $login->fetch_all_chips } ] );
  $self->_lobby_plr_update;

  return $r;
};

after '_end_game_reset' => sub {
  my ( $self, $chair ) = @_;

  # auto_rebuy
  return unless $chair->has_player;
  if ( !$chair->player->chips && $chair->player->auto_rebuy ) {
    my $avail = $chair->player->login->fetch_chips( $self->director_id );
    my $rebuy = $self->table_max > $avail ? $avail : $self->table_max;
    $chair->player->login->debit_chips( $self->director_id, $rebuy );
    $chair->player->chips($rebuy);
  }
};

before 'new_game' => sub {
  my $self = shift;
  $self->_notify_lobby_watch(

    #[ 'notify_lobby_update', $self->_fetch_lobby_update ]
    [ 'notify_lr_update', $self->_fetch_lobby_update ]
  );
};

after 'end_game' => sub {
  my $self = shift;

  $self->_notify_lobby_watch(
    [ 'notify_lr_update', $self->_fetch_lobby_update ] );
  $self->auto_start_game( $self->new_game_delay );
};

sub _lobby_plr_update {
  my $self = shift;
  my $res  = [
    'notify_lr_update',
    {
      table_id => $self->table_id,
      plr_map  => {
        map {
          $_->index =>
            { login_id => $_->player->login->id, chips => $_->player->chips }
          }
          grep { $_->has_player } @{ $self->chairs }
      },
    }
  ];
  $self->_notify_lobby_watch($res);
}

sub _notify_lobby_watch {
  my ( $self, $res ) = @_;
  $res->[1]->{table_id} = $self->table_id;
  for my $log ( grep { defined $_ } values %{ $self->lobby_watch } ) {
    $log->send($res) unless $log && $log->websocket->is_finished;
  }
}

sub _fetch_lobby_update {
  my $self  = shift;
  my $games = $self->lobby_data->{game_tots} || 1;
  my $hrs   = ceil( ( time - $self->lobby_data->{start} ) / 3600 ) || 1;
  return {
    table_id  => $self->table_id,
    avg_pot   => int( $self->lobby_data->{pot_tots} / $games ),
    plrs_flop => sprintf( "%.1f", $self->lobby_data->{plr_tots} / $games ),
    hhr       => int( $self->lobby_data->{game_tots} / $hrs ),
    plr_map   => {
      map {
        $_->index =>
          { login_id => $_->player->login->id, chips => $_->player->chips }
        }
        grep { $_->has_player } @{ $self->chairs }
    },
  };
}

# wait_bb
after 'move_button' => sub {
  my $self = shift;
  return if $self->no_blinds;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    if (!$chair->posted
      && $chair->player->wait_bb
      && defined $self->bb
      && $self->sb != $chair->index
      && $self->bb != $chair->index )
    {
      $chair->clear_is_in_hand;
    }
  }
};

after 'post_now' => sub {
  my $self = shift;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    $self->post_big( $chair->index ) unless $chair->posted;
  }
};

sub _timesup_action {
  my ( $self, $chair ) = @_;
  if ( $chair->player->timesup_count > 2 ) {
    $chair->player->timesup_count(0);
    $chair->stand_flag(1);
  }
}

sub wait {
  my ( $self, $login ) = @_;
  $self->_wait($login);
  return { success => 1 };
}

sub _wait {
  my ( $self, $login ) = @_;
  $self->wait_list->{ $login->id } = $login;
  $self->_notify_watch( [ 'notify_wait', { login_id => $login->id } ] );
}

sub unwait {
  my ( $self, $login ) = @_;
  $self->_unwait($login);
  return { success => 1 };
}

sub _unwait {
  my ( $self, $login ) = @_;
  my $log = delete $self->wait_list->{ $login->id };
  $self->_notify_watch( [ 'notify_unwait', { login_id => $login->id } ] )
    if $log;
}

sub BUILD {
  my $self = shift;
  $self->table_min( $self->_build_table_min ) unless $self->table_min;
  $self->table_max( $self->_build_table_max ) unless $self->table_max;
  $self->auto_start( $self->_build_auto_start ) unless $self->auto_start;
}

1;

