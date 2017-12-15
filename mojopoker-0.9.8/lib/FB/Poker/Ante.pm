package FB::Poker::Ante;
use Moo::Role;

has 'ante' => (
  is        => 'rw',
  #builder   => '_build_ante',
); 

sub _build_ante { 
  return;
}

has 'no_ante' => (
  is        => 'rw',
  clearer   => 1,
  builder   => '_build_no_ante',
);

sub _build_no_ante {
  return;
}

after 'post_all' => sub {
  my $self = shift;
  if ($self->ante && !$self->no_ante) {
    for my $chair ( grep { $self->chairs->[$_]->is_in_hand } ( 0 .. $#{ $self->chairs } ) ) {
      $self->post_ante( $chair );
    }
  }
};

sub post_ante {
  my ($self, $chair) = @_;
  return $self->post( $chair, $self->ante );
}

after 'BUILD' => sub {
  my $self = shift;
  $self->ante($self->_build_ante) unless $self->ante;
};

1;
