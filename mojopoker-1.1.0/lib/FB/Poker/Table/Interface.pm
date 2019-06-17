package FB::Poker::Table::Interface;
use Moo::Role;

#use Time::HiRes qw(time);
#use Data::Dumper;
use POSIX qw(ceil);

#has 'director_id' => (
#  is       => 'rw',
#  required => 1,
#);

# r, t
has 'type' => (
  is      => 'rw',
  builder => '_build_type',
);

sub _build_type {
  return '';
}

# delaer's choice and HORSE options

has 'dealer_choices' => (
  is  => 'rw',
  isa => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
);

has 'game_choice' => ( is => 'rw', );

has 'game_queue' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_game_queue',
);

sub _build_game_queue {
  return [];
}

sub next_game {
  my $self = shift;
  my $next = shift @{ $self->game_queue };
  push( @{ $self->game_queue }, $next ) if $next;
  return $next;
}

sub dealers_choice {
  my $self = shift;
  $self->action( $self->button );
  $self->valid_act( { map { $_ => 1 } qw(choice) } );
  my $handle = $self->chairs->[ $self->action ]->player->handle;
  $self->chat->write( 'd', { message => $handle . ' chooses the game.' } );
  $self->set_next_round(1);
}

# for avg/pot, plrs/flop, h/hr
has 'lobby_data' => (
  is      => 'rw',
  isa     => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_lobby_data',
);

sub _build_lobby_data {
  return {
    game_tots => 0,
    pot_tots  => 0,
    plr_tots  => 0,
    start     => time,
  };
}

before 'payout' => sub {
  my $self = shift;
  $self->lobby_data->{pot_tots} += $self->pot;
};

before 'round2' => sub {
  my $self = shift;
  $self->lobby_data->{plr_tots} += $self->live_chair_count;
};

#after 'end_game' => sub {
#  my $self = shift;
#  $self->lobby_data->{game_tots} += 1;
#};

sub auto_start_game {
  my ( $self, $delay ) = @_;
  return unless defined $delay;
  if ( $self->game_over
    && $self->auto_start
    && $self->auto_start_count >= $self->auto_start )
  {
    $self->auto_start_event(
      EV::timer $delay,
      0,
      sub {
        if ( $self->game_over
          && $self->auto_start_count >= $self->auto_start )
        {
          $self->auto_start_code;
        }
        else {
          $self->lobby_data( $self->_build_lobby_data );
        }
      }
    );
  }
  else {
    $self->lobby_data( $self->_build_lobby_data );
  }
}

sub auto_start_code {
  my $self = shift;
  $self->lobby_data->{game_tots} += 1;
  my $round = $self->dealer_choices ? 'choice' : 1;
  $self->new_game($round);
}

has 'auto_start' => (
  is      => 'rw',
  #builder => '_build_auto_start',
);

sub _build_auto_start {
  return;
}

has 'lobby_watch' => (
  is       => 'rw',
  isa      => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
  required => 1,
);

has 'auto_start_event' => ( is => 'rw', );

has 'turn_event' => ( is => 'rw', );

has 'chat' => (
  is  => 'rw',
  isa => sub { die "Not a FB::Chat!" unless $_[0]->isa('FB::Chat') },
);

# Hash of FB::Login objects
has 'watch_list' => (
  is      => 'rw',
  isa     => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_watch_list',
);

sub _build_watch_list {
  return {};
}

#has 'seated_list' => (
#  is      => 'rw',
#  isa     => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
#  builder => '_build_seated_list',
#);

#sub _build_seated_list {
#  return {};
#}

sub _find_chairs_ip {
  my ( $self, $login ) = @_;
  my @chairs;
  for my $chair ( grep { $_->has_player && $_->player->login->user->level != 10 }
    @{ $self->chairs } )
  {
    if ( $login->user->level != 10
      && $login->remote_address eq $chair->player->login->remote_address )
    {
      push @chairs, $chair;
    }
  }
  return [@chairs];
}

sub _find_chairs {
  my ( $self, $login ) = @_;
  my @chairs;
  for my $chair ( grep { $_->has_player } @{ $self->chairs } ) {
    if ( $login->id eq $chair->player->login->id ) {
      push @chairs, $chair;
    }
  }
  return [@chairs];
}

sub destroy {
  my $self = shift;
  return { table_id => $self->table_id, success => 1 };
}

sub join {

  #my ( $self, $login, $cid, $player ) = @_;
  my ( $self, $login, $opts ) = @_;
  my $rv = { table_id => $self->table_id, };

  my $cid = defined $opts->{chair} ? $opts->{chair} : $self->next_open_chair;

#  my $cid =
#    defined $opts->{chair} && $self->chairs->[ $opts->{chair} ]
#    ? $opts->{chair}
#    : $self->next_open_chair;
#
#  if ( !$self->chairs->[$cid] || $self->chairs->[$cid]->has_player ) {
  #unless ( defined $cid || !$self->chairs->[$cid]) {
  unless ( defined $cid ) {
    $rv->{success} = 0;
    $rv->{message} = 'Invalid chair';
    return $rv;
  }
  $rv->{chair} = $cid;

  if ( $self->hydra_flag ) {
    $rv->{hydra_chips} = 0;
    my $ooe = $cid % 2;
    my @hydra_chairs;
    for my $chair ( @{ $self->chairs } ) {
      if ($chair->index % 2 == $ooe) {
        if ($chair->has_player) {
          $rv->{success} = 0;
          $rv->{message} = 'Chair occupied';
          return $rv;
        }
        push @hydra_chairs, $chair->index;
        $rv->{hydra_chips} += $opts->{chips};
      }
    }
    $rv->{hydra_chairs} = [@hydra_chairs];
    #$rv->{hydra_chairs} = [@hydra_chairs];
    #$notify_res->{hydra_chairs} = $rv->{hydra_chairs};
    #for my $c (@hydra_chairs) {
    #  $self->sit($c, FB::Poker::Player->new( %$opts, login => $login ));
    #}
  }

  #my $player = FB::Poker::Player->new( %$opts, login => $login );

  #unless ($player) {
  #  $response->[1] = { success => 0, message => 'Invalid option.', %$opts };
  #  $login->send($response);
  #  return;
  #}

  #for my $t ( keys %{ $self->table_option } ) {
  #    $response->[1]->{$t} = $player->$t;
  #}
  #$self->sit( $cid, $player );
  #$self->_notify_watch( $notify_res );
  #$self->_lobby_plr_update;

  $rv->{success} = 1;
  return $rv;
}

sub unjoin {
  my ( $self, $login, $cid ) = @_;
  my $chair = $self->chairs->[$cid];
  return $self->_unjoin( $login, $chair );
}

sub _unjoin_all {
  my ( $self, $login ) = @_;
  for my $chair ( @{ $self->_find_chairs($login) } ) {
    $self->_unjoin( $login, $chair );
  }
}

sub _unjoin {
  my ( $self, $login, $chair ) = @_;

  #my $chair = $self->chairs->[$cid];
  unless ( $chair
    && $chair->has_player
    && $chair->player->login->id eq $login->id )
  {
    return {
      success  => 0,
      table_id => $self->table_id,
      message  => 'Not seated.',
    };
  }

  my $lcc = $self->live_chair_count;
  if ( !$self->game_over && $chair->is_in_hand ) {
    if ( defined $self->action && $self->action == $chair->index ) {
      $self->timesup;
    }

    elsif ( $self->legal_action('choice') || $lcc < 3 || $self->hydra_flag) {
      $self->_unseat_chair( $chair, $login );
      $self->new_game_delay(0);
      $self->end_game;
      return {
        success  => 1,
        table_id => $self->table_id,
        chair    => $chair->index
      };
    }
  }

  $self->_unseat_chair( $chair, $login );
  return {
    success  => 1,
    table_id => $self->table_id,
    chair    => $chair->index
  };

#    elsif ( $lcc < 3 ) {
#      $self->sp_flag(1);
#      $self->clear_action;
#      if ($self->legal_action('choice')) {
#        $self->new_game_delay(0);
#        $self->end_game;
#      }
#      elsif ( $lcc == 2 ) {
#        $self->_unseat_chair( $chair, $login );
#        $self->auto_play(0);
#      }
#      elsif ( $lcc == 1 ) {
#        $chair->stand_flag(1);
#        $self->auto_play(0);
#      }
#      return { success => 1, table_id => $self->table_id, chair => $chair->index };
#    }

#    elsif ( $lcc == 2 ) {
#      $self->_unseat_chair( $chair, $login );
#      $self->sp_flag(1); #silent play flag
#      $self->clear_action;
#      $self->auto_play(0);
#      return { success => 1, table_id => $self->table_id, chair => $chair->index };
#    }
#    elsif ( $lcc == 1 ) {
#      $chair->stand_flag(1);
#      $self->sp_flag(1); #silent play flag
#      $self->clear_action;
#      $self->auto_play(0);
#      return { success => 0, table_id => $self->table_id, chair => $chair->index };
#    }
#  }

#  $self->_unseat_chair( $chair, $login );
#  return { success => 1, table_id => $self->table_id, chair => $chair->index };

  # todo: take next in waiting
}

sub _unseat_chair {
  my ( $self, $chair, $login ) = @_;
  if ( defined $login ) {
    $chair->reset;
    $self->_notify_watch(
      [
        'notify_unjoin_table',
        {
          login_id => $login->id,
          chair    => $chair->index,
        }
      ]
    );

    #$self->_lobby_plr_update;
    return 1;
  }
}

sub _end_game_reset {
  my ( $self, $chair ) = @_;
  my $hp = $chair->has_player ? 1 : 0;
  my $sf = $chair->stand_flag ? 1 : 0;
  if ( $chair->has_player && $chair->stand_flag ) {
    $self->_unseat_chair( $chair, $chair->player->login );
  }
  $chair->end_game_reset;
  if ( $chair->has_player && !$self->legal_action('choice') ) {
    $chair->player->timesup_count(0);
  }
}

after 'reset_chairs' => sub {
  my $self = shift;
  for my $chair ( @{ $self->chairs } ) {
    $self->_end_game_reset($chair);
  }
};

sub watch {
  my ( $self, $login ) = @_;
  return $self->_watch($login);
}

sub _watch {
  my ( $self, $login ) = @_;
  $self->watch_list->{ $login->id } = $login;
  $self->chat->join($login);
  return {
    table_id    => $self->table_id,
    login_id    => $login->id,
    game_class  => $self->game_class,
    limit       => $self->limit,
    chair_count => $self->chair_count,
    time_bank   => $self->time_bank,
    turn_clock  => $self->turn_clock,
    small_bet   => $self->small_bet,
    #director_id => $self->director_id,
    fix_limit   => $self->fix_limit,
    pot_cap     => $self->pot_cap,
    ante        => $self->ante,
    small_blind => $self->small_blind,
    big_blind   => $self->big_blind,
    hydra_flag  => $self->hydra_flag,
    success     => 1,
  };
}

sub unwatch {
  my ( $self, $login ) = @_;
  return $self->_unwatch($login);
}

sub _unwatch {
  my ( $self, $login ) = @_;
  delete $self->watch_list->{ $login->id };
  $self->chat->unjoin($login);
  return {
    table_id => $self->table_id,
    success  => 1
  };
}

sub _notify_watch {
  my ( $self, $response ) = @_;
  $response->[1]->{table_id} = $self->table_id;
  for my $log ( values %{ $self->watch_list } ) {
    $log->send($response);
  }
}

#sub _notify_lobby_watch {
#  my ( $self, $res ) = @_;
#  $res->[1]->{table_id} = $self->table_id;
#my $res = [ 'notify_lobby_update', $self->_fetch_lobby_update ];

#  for my $log ( grep { defined $_ } values %{ $self->lobby_watch } ) {
#    $log->send($res) unless $log && $log->websocket->is_finished;
#  }
#for my $log ( grep { defined $_ } values %{ $self->lobby_watch } ) {
#for my $log ( values %{ $self->lobby_watch } ) {
#  $log->send($res);
#}
#}

sub _players_detail {
  my ( $self, $login ) = @_;
  my @details;
  for my $chair ( grep { $_->has_player } @{ $self->chairs } ) {
    my $res = {
      handle            => $chair->player->handle,
      table_id          => $self->table_id,
      status            => $chair->player->status,
      chair             => $chair->index,
      chips             => $chair->player->chips,
      in_pot            => $chair->in_pot,
      in_pot_this_round => $chair->in_pot_this_round,
      is_in_hand        => $chair->is_in_hand,
      login_id          => $chair->player->login->id,
      user_id           => $chair->player->login->user->id,
      profile_pic       => $chair->player->login->user->profile_pic,

      #sit_out           => $chair->player->sit_out,
    };

    if ( $login && $login->id eq $chair->player->login->id ) {
      $res->{cards}      = $self->_fetch_private( $chair->index );
      $res->{auto_muck}  = $chair->player->auto_muck;
      $res->{auto_rebuy} = $chair->player->auto_rebuy;
      $res->{wait_bb}    = $chair->player->wait_bb;
    }
    else {
      $res->{cards} = $self->_fetch_hole( $chair->index );
    }

    #    $res->{cards} =
    #        $login && $login->id == $chair->player->login->id
    #      ? $self->_fetch_private( $chair->index )
    #      : $self->_fetch_hole( $chair->index );

    push @details, $res;
  }
  return [@details];
}

sub _table_detail {
  my $self = shift;
  my %opts = (
    table_id     => $self->table_id,
    game_count   => $self->game_count,
    player_count => $self->true_count,
    round        => $self->round,
    action       => $self->action,
    pot          => $self->pot,
    game_over    => $self->game_over,
    last_bet     => $self->last_bet,
    community    => $self->_fetch_community,
    call_amt     => $self->_fetch_call_amt,
    valid_act    => $self->_fetch_valid_act,
  );
  if ( $self->game_choice ) {
    $opts{game_choice} = $self->game_choice;
    $opts{limit}       = $self->limit;
  }
  if ( $self->legal_action('bet') || $self->legal_action('bring') ) {
    $opts{max_bet} = $self->_fetch_max_bet;

    #$opts{min_raise} = $self->_fetch_min_raise;
    $opts{small_bet} = $self->small_bet;
  }
  if ( $self->legal_action('bring') ) {
    $opts{bring} = $self->bring;

    #$opts{max_bring} = $self->max_bring;
  }
  if ( $self->legal_action('discard') ) {
    $opts{max_discards} = $self->max_discards;
    $opts{min_discards} = $self->min_discards;
  }
  elsif ( $self->legal_action('draw') ) {
    $opts{max_draws} = $self->max_draws;
    $opts{min_draws} = $self->min_draws;
  }
  $opts{button} = $self->button if $self->can('button');
  #$opts{hydra_flag} = $self->hydra_flag if $self->hydra_flag;
  return {%opts};
}

# notifications
sub _fetch_hole {
  my ( $self, $chair ) = @_;

#return [ map { $_->up_flag ? $_->rank . $_->suit : undef } @{ $chair->cards } ];
  return [ map { $_->up_flag ? $_->rank . $_->suit : undef }
      @{ $self->chairs->[$chair]->cards } ];
}

sub _fetch_private {
  my ( $self, $chair ) = @_;
  return [ map { $_->rank . $_->suit } @{ $self->chairs->[$chair]->cards } ];
}

sub _fetch_community {
  my $self = shift;
  return [ map { $_->up_flag ? $_->rank . $_->suit : undef }
      @{ $self->community_cards } ];
}

#has 'valid_act' => (
#  is      => 'rw',
#  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
#  builder => '_build_valid_act',
#);

#sub _build_valid_act {
#  return {};
#}

sub _fetch_valid_act {
  my $self    = shift;
  my %actions = %{ $self->valid_act };
  my $call    = $self->_fetch_call_amt;
  if ( $call && $call > 0 ) {
    delete $actions{check};    # must call or fold
  }
  return [ keys %actions ];
}

around '_notify_bet' => sub {
  my ( $orig, $self, $bet ) = @_;
  my $chair = $self->chairs->[ $self->action ];
  $self->_notify_watch(
    [
      'notify_bet',
      {
        chips             => $bet,
        balance           => $chair->chips,
        chair             => $chair->index,
        table_id          => $self->table_id,
        in_pot_this_round => $chair->in_pot_this_round,
      }
    ]
  );
};

#around 'bet' => sub {
  #my ( $orig, $self, $chips ) = @_;

after 'sit' => sub {
  my ($self, $chair, $player) = @_;
  $self->_notify_watch([ 'notify_join_table', {
    login_id => $player->login->id,
    handle   => $player->handle,
    chips    => $player->chips,
    chair    => $chair,
    profile_pic => $player->login->user->profile_pic,
  }]);
};

after '_fold' => sub {
  my ($self, $chair) = @_;
  $self->_notify_fold($chair);
};

after '_notify_fold' => sub {
  my ($self, $chair) = @_;
  #my $self = shift;
  $self->_notify_watch( [ 'notify_fold', { chair => $chair->index } ] );
};

after '_notify_check' => sub {
  my $self = shift;
  $self->_notify_watch( [ 'notify_check', { chair => $self->action } ] );
};

sub _update_players {
  my $self = shift;

  #for my $chair ( values %{ $self->seated_list } ) {
  for my $chair ( grep { $_->has_player } @{ $self->chairs } ) {
    my $r = {
      chair => $chair->index,
      chips => $chair->chips,
    };
    $self->_notify_watch( [ 'player_update', $r ] );
  }
}

#sub _sit_out {
#  my ($self, $chair) = @_;
#  return unless $chair->has_player;
#  $chair->player->sit_out(1);
#  $self->_notify_watch( [ 'player_update', {
#    chair => $chair->index,
#    sit_out => 1,
#  } ] );
#}

before 'new_game' => sub {
  my $self = shift;
  my $r = { game_count => $self->game_count, };

  # moved to Interface/Ring.pm
  #$self->_notify_lobby_watch(
  #  [ 'notify_lobby_update', $self->_fetch_lobby_update ]
  #);

  $self->_notify_watch( [ 'new_game', $r ] );
  $self->chat->write( 'd', { message => 'New hand #' . $self->game_count, } );
};

around 'bet' => sub {
  my ( $orig, $self, $chips ) = @_;
  my $bet = $orig->( $self, $chips );
  if ($bet) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => $handle . ' bets ' . $bet, } );
    $self->_notify_bet($bet);
    return $bet;
  }
};

around 'check' => sub {
  my ( $orig, $self ) = @_;
  my $success = $orig->($self);
  if ($success) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => "$handle checks", } );
    $self->_notify_check;
    return $success;
  }
};

around 'fold' => sub {
  my ( $orig, $self ) = @_;
  my $success = $orig->($self);
  if ($success) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => "$handle folds", } );
    return $success;
  }
};

around 'discard' => sub {
  my ( $orig, $self, $cards ) = @_;
  my $count = $orig->( $self, $cards );
  if ( scalar @$count ) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd',
      { message => $handle . ' discards ' . scalar @$count, } );
  }
  return $count;
};

around 'draw' => sub {
  my ( $orig, $self, $cards ) = @_;
  my $map = $orig->( $self, $cards );
  my $count = scalar keys %$map;
  if ($count) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => $handle . ' draws ' . $count, } );
  }
  return $map;
};

around 'post_small' => sub {
  my ( $orig, $self, $chair ) = @_;
  my $bet    = $orig->( $self, $chair );
  my $in_pot = $self->chairs->[$chair]->in_pot_this_round;
  my $handle = $self->chairs->[$chair]->player->handle;
  $self->_notify_watch(
    [ 'notify_post', { chair => $chair, chips => $bet, in_pot => $in_pot } ] );
  $self->chat->write( 'd',
    { message => "$handle posts the small blind $bet", } );
};

around 'post_big' => sub {
  my ( $orig, $self, $chair ) = @_;
  my $bet = $orig->( $self, $chair );

 #$self->_notify_watch( [ 'notify_post', { chair => $chair, chips => $bet } ] );
  my $in_pot = $self->chairs->[$chair]->in_pot_this_round;
  $self->_notify_watch(
    [ 'notify_post', { chair => $chair, chips => $bet, in_pot => $in_pot } ] );
  my $handle = $self->chairs->[$chair]->player->handle;
  $self->chat->write( 'd', { message => "$handle posts the big blind $bet", } );
};

around 'post_ante' => sub {
  my ( $orig, $self, $chair ) = @_;
  my $bet = $orig->( $self, $chair );

 #$self->_notify_watch( [ 'notify_post', { chair => $chair, chips => $bet } ] );
  my $in_pot = $self->chairs->[$chair]->in_pot_this_round;
  $self->_notify_watch(
    [ 'notify_post', { chair => $chair, chips => $bet, in_pot => $in_pot } ] );
  my $handle = $self->chairs->[$chair]->player->handle;
  $self->chat->write( 'd', { message => "$handle posts ante $bet", } );
};

after 'move_button' => sub {
  my $self = shift;
  $self->_notify_watch( [ 'move_button', { button => $self->button } ] );
  my $handle =
      $self->chairs->[ $self->button ]
    ? $self->chairs->[ $self->button ]->player->handle
    : 'Seat #' . $self->button;

  $self->chat->write( 'd', { message => "$handle is the button", } );
};

#sub _fetch_call_amt {
#  my $self = shift;
#  if ( defined $self->action && $self->chairs->[ $self->action ] ) {
#    return $self->last_bet -
#      $self->chairs->[ $self->action ]->in_pot_this_round;
#  }
#}

#after 'begin_new_round' => sub {
before 'round_action' => sub {
  my $self = shift;
  my $res  = ['begin_new_round'];
  $res->[1] = {
    round  => $self->round,
    action => $self->action,
    pot    => $self->pot,
  };
  if ( $self->sp_flag || $self->ap_flag ) {
    $res->[1]->{auto_play} = 1;
  }
  else {
    $self->_update_players;
  }
  $self->_notify_watch($res);
};

sub set_turn_clock {
  my $self = shift;
  return unless !$self->game_over && defined $self->action;
  my $handle = $self->chairs->[ $self->action ]->player->handle;
  my $msg    = $handle . ' has ' . $self->turn_clock . ' seconds to act.';
  $self->chat->write( 'd', { message => $msg } );

  $self->turn_event(undef);
  $self->turn_event(
    EV::timer $self->turn_clock,
    0,
    sub {
      $self->activate_bank;
    }
  );
}

sub unset_turn_clock {
  my $self = shift;
  $self->turn_event(undef);
  return
    unless defined $self->action
    && $self->chairs->[ $self->action ]->has_player;
  my $player = $self->chairs->[ $self->action ]->player;
  if ( $player->time_bank_start ) {
    my $time_used = time - $player->time_bank_start;
    $player->time_bank( $player->time_bank - $time_used );
    $player->time_bank_start(0);
  }
}

sub activate_bank {
  my ( $self, $time ) = @_;
  return
       unless !$self->game_over
    && defined $self->action
    && $self->chairs->[ $self->action ]->has_player;
  my $player = $self->chairs->[ $self->action ]->player;
  my $bank   = $player->time_bank;
  unless ( $bank > 0 ) {
    $self->timesup;
    return;
  }
  $player->time_bank_start(time);
  my $handle = $player->handle;
  my $msg =
    'Time bank activated. ' . $handle . ' has ' . $bank . ' seconds to act.';
  $self->chat->write( 'd', { message => $msg } );

  $self->turn_event(undef);

  $self->turn_event(
    EV::timer $bank,
    0,
    sub {
      $self->timesup;
    }
  );
}

before 'set_next_round' => sub {
  my $self = shift;
  return if $self->sp_flag;
  $self->set_turn_clock unless $self->ap_flag;
  $self->_notify_watch( $self->_begin_new_action );
};

before 'begin_new_round' => sub {
  my $self = shift;
  $self->unset_turn_clock;
};

before 'begin_new_action' => sub {
  my $self = shift;
  $self->unset_turn_clock;
};

after 'begin_new_action' => sub {
  my $self = shift;
  return if $self->sp_flag;
  $self->set_turn_clock unless $self->ap_flag;
  $self->_notify_watch( $self->_begin_new_action );
};

sub _begin_new_action {
  my $self = shift;
  my $res  = [
    'begin_new_action',
    {
      round     => $self->round,
      action    => $self->action,
      last_bet  => $self->last_bet,
      call_amt  => $self->_fetch_call_amt,
      valid_act => $self->_fetch_valid_act,
    }
  ];
  if ( $self->legal_action('bet') || $self->legal_action('bring') ) {
    $res->[1]->{max_bet} = $self->_fetch_max_bet;

    #$res->[1]->{min_raise} = $self->_fetch_min_raise;
    $res->[1]->{small_bet} = $self->small_bet;
  }
  if ( $self->legal_action('bring') ) {
    $res->[1]->{bring} = $self->bring;

    #$res->[1]->{max_bring} = $self->max_bring;
  }
  if ( $self->legal_action('discard') ) {
    $res->[1]->{max_discards} = $self->max_discards;
    $res->[1]->{min_discards} = $self->min_discards;
  }
  elsif ( $self->legal_action('draw') ) {
    $res->[1]->{max_draws} = $self->max_draws;
    $res->[1]->{min_draws} = $self->min_draws;
  }
  return $res;
}

before 'end_game' => sub {
  my $self = shift;
  $self->unset_turn_clock;
};

after 'end_game' => sub {
  my $self = shift;
  $self->_notify_watch( ['end_game'] );

  # moved to Interface/Ring.pm

  #$self->auto_start_game( $self->new_game_delay );
  #my $res = [ 'notify_lobby_update', $self->_fetch_lobby_update ];
  #$self->_notify_lobby_watch(
  #  [ 'notify_lobby_update', $self->_fetch_lobby_update ]
  #);
  #for my $log ( values %{ $self->lobby_watch } ) {
  #  $log->send($res);
  #}
};

#sub _fetch_lobby_update {
#  my $self  = shift;
#  my $games = $self->lobby_data->{game_tots} || 1;
#  my $hrs   = ceil( ( time - $self->lobby_data->{start} ) / 3600 ) || 1;
#  return {
#    table_id  => $self->table_id,
#    avg_pot   => int( $self->lobby_data->{pot_tots} / $games ),
#    plrs_flop => sprintf( "%.1f", $self->lobby_data->{plr_tots} / $games ),
#    hhr       => int( $self->lobby_data->{game_tots} / $hrs ),
#    plr_map   => {
#      map {
#        $_->index =>
#          { login_id => $_->player->login->id, chips => $_->player->chips }
#        }
#        grep { $_->has_player } @{ $self->chairs }
#    },
#  };
#}

after 'sweep_pot' => sub {
  my $self = shift;

  #  $self->_notify_watch( [ 'sweep_pot' { pot => $self->pot } ] );
};

after 'showdown' => sub {
  my $self = shift;
  return if $self->sp_flag;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    my $handle = $chair->player->handle;
    my $cards  = $self->_fetch_hole( $chair->index );
    my $rec    = {
      chair => $chair->index,
      cards => $cards,
    };
    $self->_notify_watch( [ 'showdown', $rec ] );
    $self->chat->write(
      'd',
      {
        message => "$handle shows @$cards",
      }
    ) if scalar @$cards;
  }
};

after 'high_payout' => sub {
  my $self = shift;

  for my $winner ( @{ $self->hi_winners } ) {
    my $seat   = $winner->{winner}->index;
    my $chips  = $self->chairs->[$seat]->chips;
    my $handle = $self->chairs->[$seat]->player->handle;
    my $hand   = $self->chairs->[$seat]->hi_hand->{name}
      if defined $self->chairs->[$seat]->hi_hand;
    my $wins = $winner->{payout};
    $self->_notify_watch(
      [
        'high_winner',
        {
          chair  => $seat,
          payout => $wins,
          chips  => $chips,
        }
      ]
    );
    my $msg = "$handle wins the main pot ($wins)";
    $msg .= " with $hand" if $hand;
    $self->chat->write( 'd', { message => $msg } );
  }
};

after 'low_payout' => sub {
  my $self = shift;
  for my $winner ( @{ $self->low_winners } ) {
    my $seat   = $winner->{winner}->index;
    my $chips  = $self->chairs->[$seat]->chips;
    my $handle = $self->chairs->[$seat]->player->handle;

    #my $hand   = $self->chairs->[$seat]->low_hand->{name}
    #  if defined $self->chairs->[$seat]->low_hand;
    my $wins = $winner->{payout};
    $self->_notify_watch(
      [
        'low_winner',
        {
          chair  => $seat,
          payout => $wins,
          chips  => $chips + $wins,
        }
      ]
    );
    $self->chat->write( 'd',
      { message => "$handle wins the split pot ($wins)", } );
  }
};

#after qw(deal_down_all deal_up_all) => sub {
#  my $self = shift;

#for my $chair ( values %{ $self->seated_list } ) {
#print Dumper( $self->seated_list );

#while ( my ( $login_id, $chair ) = each %{ $self->seated_list } ) {
#  for my $chair ( grep { $_->has_player } @{ $self->chairs } ) {
#    next unless $chair->is_in_hand;
#    my $user_id  = $chair->player->login->user_id;
#    my $login_id = $chair->player->login->id;
#    my $notice   = [
#      'deal_hole',
#      {
#        user_id  => $user_id,
#        login_id => $login_id,
#        table_id => $self->table_id,
#        chair    => $chair->index,
#        cards    => $self->_fetch_private( $chair->index )
#      }
#    ];
#    $notice->[1]->{tour_id} = $self->tournament->tour_id
#      if $self->can('tournament');

#    $chair->player->login->send($notice);
#    for my $log ( values %{ $self->watch_list } ) {
#      next if $log->id == $login_id;    #player
#      $notice->[1]->{cards} = $self->_fetch_hole( $chair->index );
#      $log->send($notice);
#    }
#  }
#};

around qw(deal_down deal_up) => sub {
  my ( $orig, $self, $chair, $count ) = @_;
  return if $self->sp_flag;
  my $cards    = $orig->( $self, $chair, $count );
  my $user_id  = $chair->player->login->user->id;
  my $login_id = $chair->player->login->id;
  my $notice   = [
    'deal_hole',
    {
      user_id  => $user_id,
      login_id => $login_id,
      table_id => $self->table_id,
      chair    => $chair->index,

     #cards    => [ map { $_->up_flag ? $_->rank . $_->suit : undef } @$cards ],
      cards => [ map { $_->rank . $_->suit } @$cards ],

      #cards    => $self->_fetch_private( $chair->index )
    }
  ];

  $notice->[1]->{tour_id} = $self->tournament->tour_id
    if $self->can('tournament');

  $chair->player->login->send($notice);
  $notice->[1]->{cards} =
    [ map { $_->up_flag ? $_->rank . $_->suit : undef } @$cards ];
  for my $log ( values %{ $self->watch_list } ) {
    next if $log->id eq $login_id;    #player
    $log->send($notice);
  }
};

around 'deal_community' => sub {
  my $orig  = shift;
  my $self  = shift;
  my $cards = $orig->( $self, @_ );
  my $c     = [ map { $_->up_flag ? $_->rank . $_->suit : undef } @$cards ];
  unless ( $self->sp_flag ) {
    $self->_notify_watch(
      [
        'deal_community',
        {
          community => $c,
          table_id  => $self->table_id
        }
      ]
    );
    $self->chat->write( 'd', { message => "@$c" } );
  }
  return $cards;
};

#after 'deal_community' => sub {
#  my $self = shift;
#  $self->_notify_watch(
#    [
#      'deal_community',
#      { community => $self->_fetch_community, table_id => $self->table_id }
#    ]
#  );
#};


1;
