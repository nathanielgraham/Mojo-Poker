package FB::Poker::Chair::Chinese;
use Moo;

extends 'FB::Poker::Chair';

has 'chinese_hand' => (
  is  => 'rw',
  clearer => 1,
);

has 'front' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'middle' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'back' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

after 'reset' => sub {
  my $self = shift;
  $self->front( [] );
  $self->middle( [] );
  $self->back( [] );
  $self->clear_chinese_hand;
};

after 'end_game_reset' => sub {
  my $self = shift;
  $self->front( [] );
  $self->middle( [] );
  $self->back( [] );
  $self->clear_chinese_hand;
};

1;
