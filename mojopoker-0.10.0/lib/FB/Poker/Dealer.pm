package FB::Poker::Dealer;
use Moo;
use List::Util qw(shuffle);
use FB::Poker::Deck;
use Storable qw(dclone);
use Data::Dumper;

has 'id' => (
  is  => 'rw',
);

has 'master_deck' => (
  is  => 'rw',
  isa => sub { die "Not a FB::Poker::Deck!" unless $_[0]->isa('FB::Poker::Deck') },
  builder => '_build_master_deck',
);

sub _build_master_deck {
  return FB::Poker::Deck->new;
}

has 'deck' => (
  is      => 'rw',
  isa     => sub { die "Not a FB::Poker::Deck!" unless $_[0]->isa('FB::Poker::Deck') },
  lazy    => 1,
  builder => '_build_deck',
);

sub _build_deck {
  my $self = shift;
  return dclone $self->master_deck;
}

sub shuffle_cards {
  my ( $self, $cards ) = @_;
  $cards->cards->Reorder( shuffle $cards->cards->Keys );
}

sub shuffle_deck {
  my $self = shift;
  $self->deck( $self->_build_deck );
  $self->shuffle_cards( $self->deck );
}

sub deal {
  my $self  = shift;
  my $count = shift || 1;
  $self->reshuffle if $count > $self->deck->cards->Length;
  my %cards = $self->deck->cards->Splice( 0, $count );
  return [ values %cards ];
}

sub reshuffle {
  my $self = shift;
  while (my $card = shift @{ $self->deck->discards }) {
    $self->deck->cards->Push( $card->rank . $card->suit => $card )
  }
  $self->shuffle_cards( $self->deck );
}

sub deal_down {
  my $self = shift;
  my $count = shift || 1;
  return [ map { $_->up_flag(0); $_ } @{ $self->deal($count) } ];
}

sub deal_up {
  my $self = shift;
  my $count = shift || 1;
  return [ map { $_->up_flag(1); $_ } @{ $self->deal($count) } ];
}

sub deal_named {
  my ( $self, $cards ) = @_;
  my @hand;
  for my $card (@$cards) {
    my $val = $self->deck->cards->FETCH($card) or die "No such card: $card";
    push @hand, $val;
    $self->deck->cards->Delete($card);
  }
  return [@hand];
}

1;
