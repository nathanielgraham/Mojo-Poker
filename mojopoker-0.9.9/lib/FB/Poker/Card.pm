package FB::Poker::Card;
use Moo;

has 'suit' => (
  is => 'rw',
);

has 'rank' => (
  is => 'rw',
);

has 'id' => (
  is => 'rw',
);

has 'up_flag' => (
  is => 'rw',
);

has 'wild_flag' => (
  is => 'rw',
  clearer => 1,
  predicate => 'is_wild',
);

sub clone {
  my $self = shift;
  bless { %$self, @_ }, ref $self;
}

1;
