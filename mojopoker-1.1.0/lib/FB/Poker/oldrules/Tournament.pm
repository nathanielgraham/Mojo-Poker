package FB::Poker::Rules::Tournament;
use Moo::Role;

has 'tournament' => (
  is      => 'rw',
  isa     => sub { die "Not a tournament!" unless $_[0]->isa('FB::Poker::Tournament') },
  predicate => 'has_tournament',
);

after 'end_game' => sub {
  my $self = shift;
  return unless $self->has_tournament;
  $self->tournament->end_game($self); 
};

1;
