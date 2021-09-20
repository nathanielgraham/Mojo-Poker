package FB::Poker::Score::Badugi27;
use Moo;
use Algorithm::Combinatorics qw(combinations);

extends 'FB::Poker::Score::Badugi';

sub _build_rank_map {
  my $self = shift;
  $self->_rank_map(
    {
      '2' => '02',
      '3' => '03',
      '4' => '04',
      '5' => '05',
      '6' => '06',
      '7' => '07',
      '8' => '08',
      '9' => '09',
      'T' => '10',
      'J' => '11',
      'Q' => '12',
      'K' => '13',
      'A' => '14',
    }
  );
}

sub _build_hands {    # generates all possible Badugi hands
  my $self = shift;
  my @all_scores = ();
  for my $count ( 1 .. 4 ) {
    my @scores;
    my $iter = combinations( [ 2 .. 14 ], $count );
    while ( my $c = $iter->next ) {
      push( @scores,
        join( '', map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c ) );
    }
    $self->_hand_map->{scalar @all_scores} = $count . ' card Badugi';
    push @all_scores, sort { $b <=> $a } @scores;
  }
  $self->hands( [@all_scores] );
}

1;
