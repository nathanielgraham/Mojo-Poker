package FB::Poker::Rules::FTQ;
use Moo::Role;

has 'next_wild' => (
  is => 'rw', 
  clearer => 1,
);

sub make_wild {
  my ($self, $rank) = @_;
  for my $card ( $self->dealer->deck->cards->Values ) {
    $card->wild_flag(1) if $card->rank eq $rank;
  } 
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    for my $hole (@{ $chair->cards }) {
      if ( $hole->rank eq $rank ) {
        $hole->wild_flag(1);
      }
      else {
        $hole->clear_wild_flag;
      }
    }
  }
}

around 'deal_up' => sub {
  my ( $orig, $self, $chair, $count ) = @_;
  my $cards = $orig->($self, $chair, $count );
  for my $card (@$cards) {
    if ( $card->rank eq 'Q' ) {
      $self->next_wild(1);
      $self->chat->write( 'd', { message => "There is a Queen! Rank of next card is wild." } )
        unless ($self->sp_flag);
    }
    elsif ( $self->next_wild ) {
      $self->make_wild( $card->rank );
      $self->chat->write( 'd', { message => $card->rank . " of any suit is now wild!" } )
        unless ($self->sp_flag);
      $self->clear_next_wild;
    }
  }
  return $cards;
};

after 'reset_table' => sub {
  my $self = shift;
  $self->clear_next_wild;
};

1;
