package FB::Poker::Rules::Low;
use FB::Poker::Score::Low8;
use Moo::Role;
use Data::Dumper;

has 'low_eval' => (
  is       => 'rw',
  isa      => sub { die "Not an Eval!\n" unless $_[0]->isa('FB::Poker::Eval') },
  required => 1,
);

has 'low_winners' => (
  is  => 'rw',
  isa => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'low_hash' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { {} },
);

has 'low_mult' => (
  is      => 'rw',
  builder => '_build_low_mult',
);

sub _build_low_mult {
  my $self = shift;
  return $self->can('hi_mult') ? .5 : 1;
  #return .5;
}

before 'score' => sub {
  my $self = shift;
  $self->low_eval->community_cards( $self->community_cards );
};

after 'score_chair' => sub {
  my ( $self, $chair ) = @_;
  my $best = $self->low_eval->best_hand( $chair->cards );
  if ( $best && $best->{score} > 0 ) {
    $chair->low_hand($best);
    push @{ $self->low_hash->{ $chair->low_hand->{score} } }, $chair;
  }
};

after 'reset_table' => sub {
  my $self = shift;
  $self->low_winners( [] );
  $self->low_hash( {} );
};

before 'payout' => sub {
  my $self = shift;
  if ( scalar keys %{ $self->low_hash } && $self->can('hi_mult') ) {
    $self->hi_mult(.5);
  }
  #else {
  #  $self->hi_mult(1);
  #}
};

after 'payout' => sub {
  my $self = shift;
  $self->low_payout;
};

sub low_payout {
  my $self = shift;
  $self->pay_hash( $self->low_hash, $self->low_winners, $self->low_mult );
}

1;
