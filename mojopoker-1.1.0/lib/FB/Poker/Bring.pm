package FB::Poker::Bring;
use Moo::Role;
use Algorithm::Combinatorics qw(combinations);

sub _build_small_bet {
  my $self = shift;
  return $self->small_blind;
}

has 'bring' => ( 
  is => 'rw', 
);

sub _build_bring {
  my $self = shift;
  return $self->ante;
}

has 'bring_done' => (
  is      => 'rw',
  clearer => 1,
);

has 'bring_score' => (
  is       => 'rw',
  isa      => sub { die "Not an Score!" unless $_[0]->isa('FB::Poker::Score') },
  required => 1,
);

after 'reset_table' => sub {
  my $self = shift;
  $self->clear_bring_done;
};

around 'bet' => sub {
  my ( $orig, $self, $amount ) = @_;
  my $bet = $orig->( $self, $amount );
  if ( $bet && !$self->bring_done ) {
    if ( $self->valid_act->{bring} ) {
      $self->valid_act->{fold} = 1;
      $self->valid_act->{check} = 1;
      $self->valid_act->{bet}   = 1;
      delete $self->valid_act->{bring};
    }
    #elsif ( $self->_fetch_pot_total >= $self->max_bring ) {

    my $ante = $self->ante || 0;
    #if ( $self->last_bet >= $self->small_bet + $ante) {
    if ( $self->last_bet >= $self->small_bet ) {
      $self->bring_done(1);
    }
  }
  return $bet;
};

around '_fetch_max_bet' => sub {
  my ( $orig, $self ) = @_;
  my $limit = $orig->($self);
  if ( !$self->bring_done ) {
    my $ante = $self->ante || 0;
    my $max = $self->small_bet; 
    $limit = $max if $max > 0; 
  }
  return $limit;
};

around 'round_bet' => sub {
  my ( $orig, $self, $bet, $chips, $raise_amount ) = @_;
  return $self->bring_done
    ? $orig->( $self, $bet, $chips, $raise_amount )
    : $bet;
};

sub best_show {
  my $self = shift;
  my ($best) = sort {
    $self->bring_score->score( $self->fetch_up($b) )
      <=> $self->bring_score->score( $self->fetch_up($a) )
  } grep { $_->is_in_hand } @{ $self->chairs };
  return $best->index;
}

sub fetch_up {
  my ( $self, $chair ) = @_;
  return [ grep { $_->up_flag } @{ $chair->cards } ];
}

sub worst_show {
  my $self = shift;
  my ($worst) = sort {
    $self->bring_score->score( $self->fetch_up($a) )
      <=> $self->bring_score->score( $self->fetch_up($b) )
  } grep { $_->is_in_hand } @{ $self->chairs };
  return $worst->index;
}

after 'BUILD' => sub {
  my $self = shift;
  $self->bring( $self->_build_bring );
};

1;
