package FB::Poker::Rules::High;
use Moo::Role;

has 'hi_eval' => (
  is       => 'rw',
  isa      => sub { die "Not an Eval!\n" unless $_[0]->isa('FB::Poker::Eval') },
  required => 1,
);

has 'hi_winners' => (
  is  => 'rw',
  isa => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'hi_hash' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { {} },
);

has 'hi_mult' => (
  is      => 'rw',
  builder => '_build_hi_mult',
);

sub _build_hi_mult {
  return 1;
}

before 'score' => sub {
  my $self = shift;
  $self->hi_eval->community_cards( $self->community_cards );
};

after 'score_chair' => sub {
  my ( $self, $chair ) = @_;
  my $best = $self->hi_eval->best_hand( $chair->cards );
  if ( defined $best ) {
    $chair->hi_hand($best);
    push @{ $self->hi_hash->{ $chair->hi_hand->{score} } }, $chair;
  }
};

after 'reset_table' => sub {
  my $self = shift;
  $self->hi_winners( [] );
  $self->hi_hash( {} );
};

after 'payout' => sub {
  my $self = shift;
  $self->high_payout;
};

sub high_payout {
  my $self = shift;
  $self->pay_hash( $self->hi_hash, $self->hi_winners, $self->hi_mult );
}

1;
