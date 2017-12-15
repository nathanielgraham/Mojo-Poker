package FB::Poker::Blinds;
use Moo::Role;

#after 'move_button' => sub {
before 'move_button', 'post_blinds' => sub {
  my $self = shift;
  $self->sb($self->next_chair($self->button));
};

has 'sb' => (
  is      => 'rw',
  trigger => \&_sb_trigger
);

sub _sb_trigger {
  my ( $self, $sb ) = @_;
  $self->bb($self->next_chair($sb));
}

has 'bb' => ( 
  is => 'rw', 
);

has 'big_blind' => (
  is      => 'rw',
  builder => '_build_big_blind',
);

sub _build_big_blind {
  return 4;
}

has 'small_blind' => (
  is      => 'rw',
  builder => '_build_small_blind',
);

sub _build_small_blind {
  return 2;
}

has 'no_blinds' => (
  is      => 'rw',
  builder => '_build_no_blinds',
);

sub _build_no_blinds {
  return;
}

#sub round_starter {
#  my $self = shift;
#  return $self->button;
#}

#after 'new_game_setup' => sub {
after 'post_all' => sub {
  my $self = shift;
  $self->post_blinds;
};

sub post_blinds {
  my $self = shift;
  unless ($self->no_blinds) {
    $self->post_small( $self->sb ) if $self->small_blind;
    $self->post_big( $self->bb ) if $self->big_blind;
  }
}

sub post_big {
  my ( $self, $chair ) = @_;
  my $bet = $self->post( $chair, $self->big_blind );
  $self->chairs->[$chair]->posted(1);
  return $bet;
}

sub post_small {
  my ( $self, $chair ) = @_;
  my $bet = $self->post( $chair, $self->small_blind );
  $self->chairs->[$chair]->posted(1);
  return $bet;
}

# post unless posted 
sub post_now { }

#sub post_now {
#  my $self = shift;
#  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
#    $self->post_big( $chair->index ) if !$chair->posted;
#  }
#}

1;
