package FB::Poker::Eval;
use FB::Poker::Score::High;
use Algorithm::Combinatorics qw(combinations);
use Moo;

has 'community_cards' => (
  is      => 'rw',
  isa => sub { die "Not an array!" unless ref($_[0]) eq 'ARRAY' },
  builder => '_build_community_cards',
);

sub _build_community_cards { 
  return [];
};

has 'scorer' => (
  is      => 'rw',
  isa => sub { die "Not an Score object!" unless $_[0]->isa('FB::Poker::Score') },
#  builder => '_build_scorer',
);

#sub _build_scorer {
#  return FB::Poker::Score::High->new;
#}
 
1;
