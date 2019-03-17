package FB::Poker::Deck;
use Moo;
use FB::Poker::Card;
use Tie::IxHash;
use Data::Dumper;

has 'cards' => (
  is => 'rw',
  isa =>
    sub { die "Not a Tie::IxHash!" unless $_[0]->isa( 'Tie::IxHash') },
  builder => '_build_cards',
);

has 'discards' => (
  is => 'rw',
  isa =>
    sub { die "Not an array!" unless ref($_[0]) eq 'ARRAY' },
  default => sub { [] },
);

has 'card_type' => (
  is      => 'rw',
  builder => '_build_card_type',
);

sub _build_card_type {
  return 'FB::Poker::Card';
}

sub _build_cards {
  my $self  = shift;
  my $cards = Tie::IxHash->new;
  for my $rank (qw(2 3 4 5 6 7 8 9 T J Q K A)) {
    for my $suit (qw(c d h s)) {
      $cards->Push(
        $rank
          . $suit => $self->card_type->new(
          id   => $cards->Length,
          suit => $suit,
          rank => $rank
          )
      );
    }
  }
  return $cards;
}

sub BUILD { }

1;
