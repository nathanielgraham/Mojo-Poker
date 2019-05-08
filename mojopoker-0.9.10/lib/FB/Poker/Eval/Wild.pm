package FB::Poker::Eval::Wild;
use Algorithm::Combinatorics qw(combinations combinations_with_repetition);
use Moo;
use Data::Dumper;

extends 'FB::Poker::Eval::Community';

sub best_hand {
  my ( $self, $hole ) = @_;
  my $best = { score => 0 };
  return $best
    if $self->card_count >
      ( scalar @$hole + scalar @{ $self->community_cards } );
  my ( @wild, @normal );
  for my $card ( @$hole, @{ $self->community_cards } ) {
    if ( $card->is_wild ) {
      push @wild, $card;
    }
    else {
      push @normal, $card;
    }
  }
  my $wild_count = scalar @wild;
  $wild_count = $wild_count > 5 ? 5 : $wild_count;
  my $norm_used = 5 > $wild_count ? 5 - $wild_count : 0;
  my @wild_combos;
  if ( $wild_count > 4 ) {
    my $flat_hand = '1414141414';
    $best = {
      hand  => $flat_hand,
      score => $self->scorer->hand_score($flat_hand),
    };
  }
  elsif ( $wild_count == 4 ) {
    my @ranks = sort { $a <=> $b }
         map { $self->scorer->rank_val( $_->rank ) } @normal;
    my $high_rank = sprintf( "%02d", pop @ranks);
    my $flat_hand = join '', ($high_rank) x 5;
    $best = {
      hand  => $flat_hand,
      score => $self->scorer->hand_score($flat_hand),
    };
  }
  else {
    @wild_combos =
      combinations_with_repetition( [ map { sprintf( "%02d", $_ ) } 2 .. 14 ],
      $wild_count );
    my $norm_iter = combinations( [@normal], $norm_used );
    while ( my $norm_combo = $norm_iter->next ) {

      my %suit;
      my $max = 0;
      my @norm_ranks = map { $self->scorer->rank_val( $_->rank ) } @$norm_combo;
      for my $card (@$norm_combo) {
        $suit{ $card->suit }++;
        $max = $suit{ $card->suit } if $suit{ $card->suit } >= $max;
      }
      my $flush_possible = $max + $wild_count > 4 ? 1 : 0;

      #print "FLUSH POSSIBLE: $flush_possible\n";
      for my $wild_combo (@wild_combos) {

        #print "FLUSH POSSIBLE: $flush_possible\n";
        my $flat_combo =
          join( '', sort { $b <=> $a } ( @$wild_combo, @norm_ranks ) );

        #print "WILDS: @$wild_combo\n";
        #print "FLAT: $flat_combo\n";

        my $score = $self->scorer->hand_score($flat_combo);
        if ($flush_possible) {
          my $flush_score = $self->scorer->hand_score( $flat_combo . 's' ) || 0;
          $score = $flush_score if $flush_score > $score;
        }
        if ( defined $score && $score >= $best->{score} ) {
          $best = {
            score => $score,
            hand  => $flat_combo,
          };
        }
      }
    }
  }
  $best->{name} = $self->scorer->hand_name( $best->{score} );
  #return exists $best->{hand} ? $best : undef;
  return $best;
}

1;
