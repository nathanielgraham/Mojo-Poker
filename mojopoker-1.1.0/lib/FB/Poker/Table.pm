package FB::Poker::Table;
use Moo;
use FB::Poker::Dealer;
use FB::Poker::Chair;

#use Time::HiRes qw(time);
use List::Util qw(sum);
use Data::Dumper;

with 'FB::Poker::Blinds';
with 'FB::Poker::Ante';
with 'FB::Poker::Draw';

has 'hydra_fold' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'hydra_flag' => (
  is      => 'rw',
  builder => '_build_hydra_flag',
);

sub _build_hydra_flag {
  return;
}

has 'db' => ( is => 'rw', );

has 'auto_play_event' => ( is => 'rw', );

has 'new_game_delay' => (
  is      => 'rw',
  builder => '_build_new_game_delay',
);

sub _build_new_game_delay {
  return 4;
}

has 'show_name' => ( is => 'rw', );

has 'wild_cards' => (
  is      => 'rw',
  isa     => sub { die "not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_wild_cards',
);

sub _build_wild_cards {
  return [];
}

has 'sp_flag' => (
  is      => 'rw',
  clearer => 1,
);

has 'ap_flag' => (
  is      => 'rw',
  clearer => 1,
);

has 'auto_play_ok' => (
  is      => 'rw',
  clearer => 1,
  default => sub { return 1 },
);

has 'valid_act' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_valid_act',
);

sub _build_valid_act {
  return {};
}

has 'game_class' => ( is => 'rw', );

has 'table_id' => (
  is      => 'rw',
  trigger => \&update_tids,
);

sub update_tids {
  my ( $self, $id ) = @_;
  for my $chair ( @{ $self->chairs } ) {
    $chair->table_id($id);
  }
}

has 'dealer' => (
  is  => 'rw',
  isa => sub { die "Not a Dealer!\n" unless $_[0]->isa('FB::Poker::Dealer') },
  builder => '_build_dealer',
  handles => [qw(shuffle_deck deal)],
);

sub _build_dealer {
  return FB::Poker::Dealer->new;
}

has 'time_bank' => (
  is      => 'rw',
  default => sub { return 30 },
);

has 'pot_cap' => ( is => 'rw', );

has 'limit' => (
  is      => 'rw',
  builder => '_build_limit',
);

sub _build_limit {
  return 'NL';    # types: NL, PL, FL
}

has 'fix_limit' => ( is => 'rw', );

sub _fetch_max_bet {
  my $self = shift;
  return unless defined $self->action;

  my $chips = $self->chairs->[ $self->action ]->chips;
  my $call  = $self->_fetch_call_amt;
  my $pl =
    $self->next_round > 1 ? $self->_fetch_pot_total : $call + $self->small_bet;
  my $limit =
      $self->limit eq 'PL' ? $pl
    : $self->limit eq 'FL' ? $self->fix_limit + $call
    :                        $chips;

  if ( $limit > $chips ) {
    $limit = $chips;
  }
  if ( $self->pot_cap && $limit > $self->pot_cap ) {
    $limit = $self->pot_cap;
  }
  return $limit;
}

has 'small_bet' => (
  is      => 'rw',
  trigger => \&_small_bet_trigger,
);

sub _small_bet_trigger {
  my $self = shift;
  if ( $self->limit eq 'FL' ) {
    $self->fix_limit( $self->small_bet );
    $self->pot_cap( $self->fix_limit * 5 );
  }
}

sub _build_small_bet {
  my $self = shift;
  return $self->big_blind;

 #return $self->big_blind && !$self->no_blinds ? $self->big_blind : $self->ante;
}

has 'turn_clock' => (
  is      => 'rw',
  default => sub { return 15 },
);

has 'community_cards' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_community_cards',
);

sub _build_community_cards {
  return [];
}

has '_round_actions' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_round_actions',
);

sub _build_round_actions {
  my $self = shift;
  return {
    choice => sub {
      $self->dealers_choice;
    },
    1 => sub {
      $self->round1;
    },
    2 => sub {
      $self->round2;
    },
    3 => sub {
      $self->round3;
    },
    4 => sub {
      $self->round4;
    },
    5 => sub {
      $self->round5;
    },
    6 => sub {
      $self->round6;
    },
    7 => sub {
      $self->round7;
    },
    8 => sub {
      $self->round8;
    },
    9 => sub {
      $self->round9;
    },
  };
}

sub dealers_choice { }
sub round1         { }
sub round2         { }
sub round3         { }
sub round4         { }
sub round5         { }
sub round6         { }
sub round7         { }
sub round8         { }
sub round9         { }
sub post_all       { }

sub move_button {
  my $self = shift;
  $self->button( $self->next_chair( $self->button ) );
}

sub round_action {
  my ( $self, $round ) = @_;
  if ( exists $self->_round_actions->{$round} ) {
    &{ $self->_round_actions->{$round} };
  }
}

has 'chairs' => (
  is  => 'rw',
  isa => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

#has 'new_chair' => (
#  is  => 'rw',
#  isa => sub {
#    die "Not an FB::Poker::Chair.\n" unless $_[0]->isa('FB::Poker::Chair');
#  },
#  builder => '_build_new_chair',
#);

#sub _build_new_chair {
#  return FB::Poker::Chair->new;
#}

has 'chair_count' => (
  is      => 'rw',
  default => sub { return 6 },
);

has 'round' => (
  is      => 'rw',
  clearer => 1,
);

has 'next_round' => (
  is      => 'rw',
  clearer => 1,
);

has 'pot' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'last_bet' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'game_count' => (    # Bool
  is      => 'rw',
  default => sub { return 0 },
);

has 'action' => (
  is      => 'rw',
  clearer => 1,
  builder => '_build_action',
);

sub action_trigger {
}

sub _build_action {
  return;
}

has 'button' => (
  is      => 'rw',
  builder => '_build_button',
);

sub _build_button {
  return 0;
}

has 'game_over' => (    # Bool
  is      => 'rw',
  default => sub { return 1 },
);

sub true_count {
  my $self = shift;
  return scalar grep { $_->has_player } @{ $self->chairs };
}

sub have_chips_count {
  my $self = shift;
  return scalar grep { $_->is_in_hand && $_->chips } @{ $self->chairs };
}

sub live_chair_count {
  my $self = shift;
  return scalar grep { $_->is_in_hand } @{ $self->chairs };
}

sub auto_start_count {
  my $self = shift;
  return scalar grep { $_->chips && !$_->player->sit_out } @{ $self->chairs };
}

sub next_chair {
  my ( $self, $chair ) = @_;

  my @act =
    grep { $self->chairs->[$_]->is_in_hand } ( 0 .. $#{ $self->chairs } );

  for (@act) {
    if ( $_ > $chair ) {
      return $_;
    }
  }
  return shift(@act);
}

sub next_open_chair {
  my ( $self, $chair ) = @_;
  for my $chair ( 0 .. $#{ $self->chairs } ) {
    return $chair unless $self->chairs->[$chair]->has_player;
  }
}

sub prev_in_hand {
  my ( $self, $chair ) = @_;
  my @act =
    grep { $self->chairs->[$_]->is_in_hand } ( 0 .. $#{ $self->chairs } );
  for ( reverse @act ) {
    if ( $chair > $_ ) {
      return $_;
    }
  }
  return pop(@act);
}

sub sweep_pot {
  my $self = shift;
  for my $i ( 0 .. $#{ $self->chairs } ) {
    if ( $self->chairs->[$i]->in_pot_this_round ) {
      $self->pot( $self->pot + $self->chairs->[$i]->in_pot_this_round );
      $self->chairs->[$i]->in_pot_this_round(0);
    }
  }
}

sub adjust_bet {
  my $self = shift;

  my @sorted = sort {
    $self->chairs->[$b]->in_pot_this_round <=> $self->chairs->[$a]
      ->in_pot_this_round
  } ( 0 .. $#{ $self->chairs } );
  my $diff =
    $self->chairs->[ $sorted[0] ]->in_pot_this_round -
    $self->chairs->[ $sorted[1] ]->in_pot_this_round;
  if ($diff) {
    $self->chairs->[ $sorted[0] ]
      ->in_pot_this_round( $self->chairs->[ $sorted[1] ]->in_pot_this_round );
    $self->chairs->[ $sorted[0] ]
      ->chips( $self->chairs->[ $sorted[0] ]->chips + $diff );
    $self->chairs->[ $sorted[0] ]
      ->in_pot( $self->chairs->[ $sorted[0] ]->in_pot - $diff );
  }
}

sub betting_done {
  my $self = shift;

  my $discard_round = $self->legal_action('discard')
    || $self->legal_action('draw');
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    return 0
      unless ( $chair->has_acted
      && $chair->in_pot_this_round == $self->last_bet )
      || ( $chair->chips == 0 && !$discard_round );
  }
  return 1;
}

sub action_done {
  my $self = shift;
  return unless ( defined $self->action && !$self->game_over );
  $self->chairs->[ $self->action ]->has_acted(1);

  if ( $self->live_chair_count < 2 || $self->hydra_fold ) {

    # ZERO OR ONE PLAYERS
    $self->new_game_delay(0);
    $self->end_game;
    return;

    #$self->sp_flag(1); #silent play flag
    #$self->clear_action;
    #$self->auto_play(0);
    #return;
  }

  my $betting_done = $self->betting_done;

  #if ( $betting_done && $self->auto_play_ok && $self->have_chips_count < 2 ) {
  #my $ap_count = $self->hydra_flag ? int( $self->chair_count / 2 ) : 2;
  if ( $betting_done && $self->auto_play_ok && $self->have_chips_count < 2 ) {
    $self->ap_flag(1);    #auto play flag
    $self->clear_action;
    $self->auto_play(1);
    return;
  }

  if ($betting_done) {
    $self->begin_new_round;
  }

  # NEW ACTION
  else {
    $self->begin_new_action;
  }
  return unless defined $self->action;

  my $discard_round = $self->legal_action('discard')
    || $self->legal_action('draw');

  if ( $self->chairs->[ $self->action ]->check_fold ) {
    $self->timesup;
  }

  # skip players that can't do anything
  elsif ( $self->chairs->[ $self->action ]->chips == 0 && !$discard_round ) {
    $self->action_done;
  }
}

sub auto_play {
  my ( $self, $delay ) = @_;

  # sweep_pot
  $self->adjust_bet;
  $self->sweep_pot;

  $self->auto_play_event(undef);

  $self->auto_play_event(
    EV::timer $delay,
    0,
    sub {
      $self->round( $self->next_round );
      $self->round_action( $self->round );
      $self->auto_play($delay) unless $self->game_over;
    }
  );
}

sub legal_action {
  my ( $self, $act ) = @_;
  my %actions = %{ $self->valid_act };
  my $call    = $self->_fetch_call_amt;
  if ( $call && $call > 0 ) {
    delete $actions{check};
  }
  return $actions{$act} ? 1 : 0;
}

sub timesup {
  my $self = shift;
  return
       unless !$self->game_over
    && defined $self->action
    && $self->chairs->[ $self->action ]->has_player;

  my $chair = $self->chairs->[ $self->action ];
  my $tc    = $chair->player->timesup_count + 1;
  $chair->player->timesup_count($tc);
  $self->_timesup_action($chair);

  if ( $self->legal_action('check') ) {
    $self->check;
    #$self->_notify_check;
  }
  elsif ( $self->legal_action('fold') ) {
    $self->fold;
    #$self->_notify_fold;
  }
  elsif ( $self->legal_action('bring') ) {
    my $bet = $self->bet( $self->small_bet );
    #$self->_notify_bet($bet) if $bet;
  }
  else {
    $self->new_game_delay(0);
    $self->sp_flag(1);
    $self->end_game;
    return;
  }
  $self->action_done;
}

sub _timesup_action { }

sub _notify_bet {
  my ( $self, $bet ) = @_;
}

sub _notify_fold  { }
sub _notify_check { }

sub begin_new_round {
  my $self = shift;

  # clear lastbet
  $self->last_bet(0);

  # clear has_acted flag
  for my $chair ( @{ $self->chairs } ) {
    $chair->clear_has_acted;
  }

  # sweep_pot
  $self->adjust_bet;
  $self->sweep_pot;

  # next round action
  if ( $self->next_round ) {
    $self->round( $self->next_round );
    $self->round_action( $self->round );
  }
}

sub begin_new_action {
  my $self = shift;

  $self->action( $self->next_chair( $self->action ) );
}

sub payout {
  my $self = shift;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    $chair->max_win(
      sum(
        map { $chair->in_pot < $_->in_pot ? $chair->in_pot : $_->in_pot }
        grep { $_->in_pot } @{ $self->chairs }
      )
    );
  }
}

sub high_payout { }
sub low_payout  { }

sub pay_hash {
  my ( $self, $score_hash, $winners, $mult ) = @_;
  die "pot mult not between 0 and 1!" if $mult > 1 || $mult < 0;
  my $this_pot = $self->pot * $mult;
  my @c = grep { $_->is_in_hand } @{ $self->chairs };
  $score_hash = { 1 => [@c] } if scalar @c == 1;

SCORE:
  for my $score ( sort { $b <=> $a } ( keys %{$score_hash} ) ) {
    my $winner_count = scalar @{ $score_hash->{$score} };
    for my $winner ( @{ $score_hash->{$score} } ) {
      last SCORE unless $this_pot > 0;
      my $max_win = ( $winner->max_win / $winner_count ) * $mult;
      my $payout =
        sprintf( "%.2f", $max_win < $this_pot ? $max_win : $this_pot ) + 0;
      if ($payout) {
        $this_pot -= $payout;
        $winner->chips( $winner->chips + $payout );
        push @{$winners}, { winner => $winner, payout => $payout };
      }
    }
  }
}

sub _fetch_pot_total {
  my $self  = shift;
  my $total = $self->pot;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    $total += $chair->in_pot_this_round;
  }
  return $total;
}

sub bet {
  my ( $self, $amount ) = @_;
  my $chair = $self->action;
  my $bet = $self->post( $chair, $amount );
  return $bet;
}

sub _fetch_call_amt {
  my $self = shift;
  if ( defined $self->action && $self->chairs->[ $self->action ] ) {
    return $self->last_bet -
      $self->chairs->[ $self->action ]->in_pot_this_round;
  }
}

sub post {
  my ( $self, $chair, $amount ) = @_;
  return
    unless ( defined $chair
    && defined $self->chairs->[$chair]
    && $amount
    && $amount > 0 );

  my $chips       = $self->chairs->[$chair]->chips;
  my $call_amount = $self->_fetch_call_amt;
  $call_amount = $chips > $call_amount ? $call_amount : $chips;
  my $raise_amount = $amount > $call_amount ? $amount - $call_amount : 0;
  my $max_bet      = $self->_fetch_max_bet;
  my $max_raise    = $max_bet - $call_amount if defined $max_bet;
  $raise_amount = $max_raise
    if $max_raise && $raise_amount > $max_raise;

  #my $bet = $call_amount + $raise_amount;
  my $bet =
    $self->round_bet( $call_amount + $raise_amount, $chips, $raise_amount );

  #$bet = $self->round_bet( $bet, $chips, $raise_amount );
  if ( $max_bet && $bet > $max_bet ) {
    $bet = $max_bet;
  }

  my $total_bet = $bet + $self->chairs->[$chair]->in_pot_this_round;

  # must match current bet unless all in
  return
    if ( $total_bet < $self->last_bet
    && $bet < $self->chairs->[$chair]->chips );

  $self->chairs->[$chair]->chips( $self->chairs->[$chair]->chips - $bet );
  $self->chairs->[$chair]->in_pot( $self->chairs->[$chair]->in_pot + $bet );
  $self->chairs->[$chair]
    ->in_pot_this_round( $self->chairs->[$chair]->in_pot_this_round + $bet );

  if ( $total_bet > $self->last_bet ) {
    $self->last_bet($total_bet);

    #$self->last_act($chair);
  }

  #$self->max_raise( $self->_build_max_raise );
  return $bet;
}

sub round_bet {
  my ( $self, $bet, $chips, $raise_amount ) = @_;
  if ( $self->next_round > 1 && $bet != $chips ) {
    $bet -= ( $raise_amount % $self->small_bet );
  }
  return $bet;
}

sub fold {
  my $self  = shift;
  my $chair = $self->chairs->[ $self->action ];
  $self->_fold($chair);

  if ( $self->hydra_flag ) {
    my $login_id = $chair->player->login->id;
    $self->hydra_fold(1);
    for my $c ( grep { $_->has_player && $_->player->login->id == $login_id } @{ $self->chairs } ) { 
      $self->_fold($c);
    }
  }
  else {
    $self->_fold($chair);
  }
  return 1;
}

sub _fold {
  my ($self, $chair)  = @_;
  $self->adjust_bet if $self->live_chair_count == 2;
  push @{ $self->dealer->deck->discards }, @{ $chair->cards };
  $chair->clear_is_in_hand;
  $chair->cards( [] );
  return 1;
}

sub check {
  my $self  = shift;
  my $chair = $self->action;
  return 1
    if ( defined $chair
    && $self->chairs->[$chair]->in_pot_this_round >= $self->last_bet );
}

sub set_next_round {
  my ( $self, $round ) = @_;
  $self->next_round($round);
}

sub reset_chairs { }

sub end_game {
  my $self = shift;
  $self->turn_event(undef);
  $self->sweep_pot;

  #$self->score;
  if ( $self->live_chair_count > 1 ) {
    $self->score;
    $self->showdown;
    $self->new_game_delay(4);
  }
  else {
    $self->new_game_delay(4);
  }
  $self->payout;
  $self->pot(0);
  $self->clear_round;
  $self->clear_next_round;
  $self->clear_action;
  $self->clear_sp_flag;
  $self->clear_ap_flag;
  $self->reset_chairs;
  $self->hydra_fold(0) if $self->hydra_flag;
  $self->game_over(1);
}

sub showdown {
  my $self = shift;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    for my $card ( @{ $chair->cards } ) {
      $card->up_flag(1);
    }
  }
}

sub _new_game_reset {
  my ( $self, $chair ) = @_;
  $chair->new_game_reset;
}

sub new_game {
  my ( $self, $round ) = @_;

  $self->auto_start_event(undef);
  $self->auto_play_event(undef);
  $self->turn_event(undef);

  $round = defined $round ? $round : 1;

  # reset table
  $self->reset_table;

  # reset chairs
  for my $chair ( @{ $self->chairs } ) {
    $self->_new_game_reset($chair);
  }

  $self->game_count( $self->game_count + 1 );

  # shuffle
  $self->dealer->shuffle_deck;

  # next round
  $self->next_round($round);

  # game setup
  $self->move_button;

  # begin
  $self->begin_new_round;
}

sub deal_down_all {
  my ( $self, $count ) = @_;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    $self->deal_down( $chair, $count );
  }
}

sub deal_order {
  my ( $self, $begin, $chair ) = @_;
  my $r = $chair->index - $begin;
  return $r < 0 ? $r + $self->chair_count : $r;
}

sub deal_up_all {
  my ( $self, $count ) = @_;
  my $begin = $self->next_chair( $self->button );

  #for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
  for my $chair (
    sort { $self->deal_order( $begin, $a ) <=> $self->deal_order( $begin, $b ) }
    grep { $_->is_in_hand } @{ $self->chairs }
    )
  {
    $self->deal_up( $chair, $count );
  }
}

sub deal_down {
  my ( $self, $chair, $count ) = @_;
  my $cards = $self->dealer->deal_down($count);
  push @{ $chair->cards }, @{$cards};
  return $cards;
}

sub deal_up {
  my ( $self, $chair, $count ) = @_;
  my $cards = $self->dealer->deal_up($count);
  push @{ $chair->cards }, @{$cards};
  return $cards;
}

sub deal_community {
  my ( $self, $count ) = @_;
  my $cards = $self->dealer->deal_up($count);
  push @{ $self->community_cards }, @$cards;
  return $cards;
}

sub reset_table {
  my $self = shift;
  $self->game_over(0);
  $self->pot(0);
  $self->last_bet(0);
  $self->clear_round;

  #$self->clear_sp_flag;
  #$self->clear_ap_flag;
  $self->new_game_delay( $self->_build_new_game_delay );

  #$self->round(1);
  #$self->clear_last_act;
  $self->community_cards( [] );

  # $self->game_count( $self->game_count + 1 );
  # $self->dealer->shuffle_deck;
}

#sub add_chair {
#  my $self  = shift;
#  my $chair = $self->new_chair->clone;
#  $chair->index( scalar @{ $self->chairs } );
#  push( @{ $self->chairs }, $chair );
#}

#sub add_players {
#  my $self = shift;
#  $self->sit( 0, FB::Poker::Player->new( chips => 50 ) );
#  $self->chairs->[0]->is_in_hand(1);
#  $self->sit( 1, FB::Poker::Player->new( chips => 50 ) );
#  $self->chairs->[1]->is_in_hand(1);

#$self->sit(2, FB::Poker::Player->new(chips => 50));
#$self->chairs->[2]->is_in_hand(1);
#$self->sit(3, FB::Poker::Player->new(chips => 50));
#$self->chairs->[3]->is_in_hand(1);
#}

sub score {
  my $self = shift;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    $self->score_chair($chair);
  }
}

sub score_chair { }

sub sit {
  my ( $self, $chair, $player ) = @_;
  for my $p (qw(time_bank)) {
    $player->$p( $self->$p );
  }
  $self->chairs->[$chair]->sit($player);
  return 1;
}

#sub stand {
#  my ( $self, $chair ) = @_;
#  $self->chairs->[$chair]->stand;

#  if ($self->action == $chair) {
#    $self->timesup;
#  }
#  elsif ($self->live_chair_count < 2) {
#    $self->auto_play;
#  }
#}

# BUILD
sub BUILD {
  my $self = shift;

  $self->chairs(
    [
      map { FB::Poker::Chair->new( index => $_ ) }
        ( 0 .. ( $self->chair_count - 1 ) )
    ]
  );

  #for ( 1 .. $self->chair_count ) {
  #  $self->add_chair;
  #}
  $self->small_bet( $self->_build_small_bet ) unless $self->small_bet;
  for my $card ( @{ $self->wild_cards } ) {
    my $val = $self->dealer->master_deck->cards->FETCH($card)
      || FB::Poker::Card->new( rank => '', suit => $card );
    $val->wild_flag(1);
    $self->dealer->master_deck->cards->Push( $card => $val );
  }
}

1;
