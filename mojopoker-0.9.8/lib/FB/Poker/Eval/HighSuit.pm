package FB::Poker::Eval::HighSuit;
use Moo;

extends 'FB::Poker::Eval';

has 'high_suit' => (
  is      => 'rw',
  builder => '_build_high_suit',
);

sub _build_high_suit {    # High Chicago
  return 's';
}

sub best_hand {
  my ( $self, $hole ) = @_;
  return $self->scorer->score($hole, $self->high_suit);
}

1;
