package FB::Poker::Score::HighSuit;
use Moo;

extends 'FB::Poker::Score';

sub score {
  my ( $self, $cards, $suit ) = @_;
  my ($high_card) =
    sort { $self->rank_val( $b->rank ) <=> $self->rank_val( $a->rank ) }
    grep { !$_->up_flag && $_->suit eq $suit } @$cards;

  if ($high_card) {
    return {
      score => $self->rank_val( $high_card->rank ),
      hand  => [$high_card],
    };
  }
}

1;
