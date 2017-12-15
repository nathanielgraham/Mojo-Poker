package FB::Poker::Eval::Bitch;
use Moo;

extends 'FB::Poker::Eval';

has 'bitch_card' => (
  is      => 'rw',
  builder => '_build_bitch_card',
);

sub _build_bitch_card { # The Bitch
  return 'Qs';
}

sub best_hand {
  my ( $self, $hole ) = @_;
  for my $card (@$hole) {
    if ($card->rank . $card->suit eq $self->bitch_card) {
      return { score => 100, hand => $self->bitch_card };
    }
  }
  return { score => 0 };
}

1;
