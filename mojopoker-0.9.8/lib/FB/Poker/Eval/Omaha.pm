package FB::Poker::Eval::Omaha;
use Algorithm::Combinatorics qw(combinations);
use Moo;

extends 'FB::Poker::Eval';

has '_combos' => (
  is      => 'rw',
  isa => sub { die "Not an Score object!" unless ref($_[0]) eq 'ARRAY' },
  predicate => 'has_combos',
);

after 'community_cards' => sub {
  my ($self, $cards) = @_;
  return unless $cards && scalar @$cards >= 3;
  my @combos = combinations( $self->community_cards, 3 );
  $self->_combos([ @combos ]);
};

sub best_hand {
  my ( $self, $hole ) = @_;
  # $self->build_combos unless $self->has_combos;
  my $best = { score => 0 };
  return $best
    if 5 >
      ( scalar @$hole + scalar @{ $self->community_cards } );

  my $iter = combinations( $hole, 2 );
  while ( my $hole_combo = $iter->next ) {
    for my $combo (@{$self->_combos}) {
      my $hand = [ @$hole_combo, @$combo ];
      my $score = $self->scorer->score($hand);
      if (defined $score && $score >= $best->{score}) {
        $best = {
          score => $score,
          hand  => $hand,
        };
      }
    }
  }
  $best->{name} = $self->scorer->hand_name($best->{score}),
  #return exists $best->{hand} ? $best : undef;
  return $best;

}

1;
