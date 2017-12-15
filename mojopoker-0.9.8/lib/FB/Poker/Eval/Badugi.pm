package FB::Poker::Eval::Badugi;
use Algorithm::Combinatorics qw(combinations);
use Moo;
use FB::Poker::Score::Badugi;
use FB::Poker::Eval::Badugi;

extends 'FB::Poker::Eval';

#sub _build_scorer {
#  return FB::Poker::Score::Badugi->new;
#}

sub best_hand {
  my ( $self, $hole ) = @_;
  my $best = { score => 0 };
  my $iter = combinations( $hole, scalar @$hole > 4 ? 4 : scalar @$hole);
  while (my $combo = $iter->next ) {
    my (@list, %seen);
    for my $c (sort { $self->scorer->_rank_map->{$a->rank} <=> $self->scorer->_rank_map->{$b->rank} } @$combo) {
      if ( !$seen{ $c->suit } && !$seen{ $c->rank } ) {
        push @list, $c;
        $seen{ $c->suit }++; 
        $seen{ $c->rank }++; 
      }
    }
    my $score = $self->scorer->score( [@list] );
    if ( defined $score && $score >= $best->{score} ) {
      $best = {
        score => $score,
        hand  => \@list,
      };
    }
  }
  $best->{name} = $self->scorer->hand_name( $best->{score} );
  return $best;
}

1;
