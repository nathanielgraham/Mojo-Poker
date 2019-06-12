package FB::Poker::Score::Low8;
use Moo;
use Algorithm::Combinatorics qw(combinations);

extends 'FB::Poker::Score';

sub _build_rank_map {
  my $self = shift;
  $self->_rank_map({
    'A' => '01',
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
  });
}

sub _build_hands {  # generates all possible low8 hands
  my $self = shift;
  my @scores;
  my $iter = combinations([1..8], 5);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
  }
  $self->hands([ sort { $b <=> $a } @scores ]);
  #$self->_hand_map( {} );
}

1;
