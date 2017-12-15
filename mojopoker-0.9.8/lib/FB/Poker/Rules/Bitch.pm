package FB::Poker::Rules::Bitch;
use Moo::Role;

with 'FB::Poker::Rules::Stud';

has 'bitch_card' => (
  is => 'rw',
  default => sub { return 'Qs' },
  clearer => 1,
);

has 'bitch_flag' => (
  is => 'rw',
  clearer => 1,
);

has 'redeal_event' => (
  is => 'rw',
);

around 'deal_up' => sub {
  my ( $orig, $self, $chair, $count ) = @_;
  my $cards = $orig->($self, $chair, $count);
  for my $card (@$cards) {
    if ( $card->rank . $card->suit eq $self->bitch_card ) {
      $self->bitch_flag(1);
      $self->chat->write( 'd', { message => "The Bitch! Shuffle up and re-deal." } );
    }
  }
  return $cards;
};

after 'set_next_round' => sub {
  my $self = shift;
  return unless $self->bitch_flag;
  $self->auto_start_event(undef);
  $self->auto_play_event(undef);
  $self->turn_event(undef);
  $self->redeal_event(undef);
  $self->game_over(1);
  $self->clear_bitch_flag;
  $self->last_bet(0);
  $self->clear_round;
  $self->clear_next_round;
  $self->clear_action;
  $self->clear_bring_done;
  $self->clear_sp_flag;
  $self->clear_ap_flag;
  $self->clear_bring_done;
  #$self->next_round(1);
  $self->last_bet(0);
  $self->sweep_pot;
  $self->shuffle_deck;
  my $nob = $self->no_blinds;
  $self->no_blinds(1);
  my $noa = $self->no_ante;
  $self->no_ante(1);
  if ($self->live_chair_count < 2) {
    $self->auto_start_game( $self->new_game_delay );
    return;
  }

  $self->_notify_watch( [ 'table_update', { hide_buttons => 1 } ] );
  $self->redeal_event( EV::timer 5, 0, sub {
    for my $c ( @{ $self->chairs } ) {
      $c->cards( [] );
      my $r = {
        chair => $c->index,
        cards => $c->cards,
        chips => $c->chips,
      };
      $self->_notify_watch( [ 'player_update', $r ] );
    }
    $self->next_round(1);
    $self->no_blinds($nob);
    $self->no_ante($noa);
    $self->game_over(0);
    $self->begin_new_round;
  });
};

1;
