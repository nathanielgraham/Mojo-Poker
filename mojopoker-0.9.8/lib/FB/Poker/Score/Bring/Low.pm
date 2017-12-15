package FB::Poker::Score::Bring::Low;
use Moo;
use Algorithm::Combinatorics qw(combinations);
use List::Util qw(max);

extends 'FB::Poker::Score::Bring::High';

after _build_hands => sub {
  my $self = shift;
  $self->hands( [ reverse @{ $self->hands } ] );
};

1;
