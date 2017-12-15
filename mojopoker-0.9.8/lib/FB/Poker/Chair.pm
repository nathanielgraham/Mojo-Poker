package FB::Poker::Chair;
use Moo;
use FB::Poker::Player;

sub chips {
  my ($self, $amt) = @_;
  return 0 unless $self->has_player;
  return defined $amt ? $self->player->chips($amt) : $self->player->chips;
}

has 'table_id' => (
  is  => 'rw',
);

has 'has_acted' => (
  is  => 'rw',
  clearer => 1,
);

has 'stand_flag' => (
  is  => 'rw',
  clearer => 1,
);

#has 'sit_out' => (
#  is  => 'rw',
#  clearer => 1,
#);

has 'check_fold' => (
  is  => 'rw',
  clearer => 1,
);

has 'cards' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'posted' => (
  is      => 'rw',
  clearer => 1,
);

sub payout {
  my ($self, $amt) = @_;
  return 0 unless $self->has_player;
  return defined $amt ? $self->player->payout($amt) : $self->player->payout;
}

has 'index' => ( is => 'rw', );

has 'hi_hand' => ( 
  is => 'rw', 
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  clearer => 1,
);

has 'low_hand' => ( 
  is => 'rw', 
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  clearer => 1,
);

has 'is_in_hand' => (
  is      => 'rw',
  clearer => 1,
  # default => sub { return 0; },
);

has 'in_pot' => (
  is      => 'rw',
  default => sub { return 0; },
);

has 'in_pot_this_round' => (
  is      => 'rw',
  default => sub { return 0; },
);

has 'player' => (
  is => 'rw',
  isa => sub { die "Not a FB::Poker::Player!" unless $_[0]->isa('FB::Poker::Player') },
  clearer => 1,
  predicate => 'has_player',
);

has 'max_win' => (
  is => 'rw',
  default => sub { return 0; },
);

sub reset {
  my $self = shift;
  $self->clear_player;
  $self->clear_stand_flag;
  $self->clear_check_fold;
  $self->clear_has_acted;
  $self->clear_is_in_hand;
  $self->clear_posted;
  #$self->clear_post_now;
  $self->clear_hi_hand;
  $self->clear_low_hand;
  #$self->in_pot(0);
  #$self->in_pot_this_round(0);
  $self->max_win(0);
  $self->cards( [] );
}

sub end_game_reset {
  my $self = shift;
  $self->clear_check_fold;
  $self->clear_is_in_hand;
  $self->clear_has_acted;
  $self->clear_hi_hand;
  $self->clear_low_hand;
  $self->in_pot(0);
  $self->in_pot_this_round(0);
  $self->max_win(0);
  $self->cards( [] );
  #if ($self->has_player) {
  #  $self->player->timesup_count(0); 
  #}
}

sub new_game_reset {
  my $self = shift;
  if ( $self->has_player && $self->player->chips && !$self->player->sit_out) {
    $self->is_in_hand(1);
  }
  else {
    $self->clear_is_in_hand;
  }
}

sub sit {
  my ($self, $player) = @_;
  $player->table_id( $self->table_id );
  $self->reset;
  $self->player($player); 
}

#sub stand {
#  my $self = shift;
#  if ($self->is_in_hand) {
#    $self->check_fold(1);
#    $self->stand_flag(1);
#  }
#  else {
#    $self->reset;
#  }
#}

sub clone {
  my $self = shift;
  bless {%$self, @_}, ref $self;
} 

1;
