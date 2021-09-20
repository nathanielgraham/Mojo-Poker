package FB::Poker::Eval::Community;
use Algorithm::Combinatorics qw(combinations);
use Moo;
use Data::Dumper;

extends 'FB::Poker::Eval';

has 'card_count' => (
  is      => 'rw',
  builder => '_build_card_count',
);

sub _build_card_count {
  return 5;
}

sub best_hand {
  my ( $self, $hole ) = @_;
  my $best = { score => 0 };
  return $best
    if $self->card_count >
      ( scalar @$hole + scalar @{ $self->community_cards } );
  my $iter = $self->make_iter($hole);
  while ( my $combo = $iter->next ) {
    my $score = $self->scorer->score($combo);
    if ( defined $score && $score >= $best->{score} ) {
      $best = {
        score => $score,
        hand  => $combo,
      };
    }
  }
  $best->{name} = $self->scorer->hand_name( $best->{score} );

  #return exists $best->{hand} ? $best : undef;
  return $best;
}

sub make_iter {
  my ( $self, $hole ) = @_;
  my $iter =
    combinations( [ @$hole, @{ $self->community_cards } ], $self->card_count );
  return $iter;
}

1;
