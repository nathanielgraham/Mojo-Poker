package FB::Poker::Draw;
use Moo::Role;
use Data::Dumper;

has 'max_draws' => (
  is      => 'rw',
  #default => sub { return 3 },
  clearer => 1,
);

has 'min_draws' => (
  is      => 'rw',
  #default => sub { return 0 },
  clearer => 1,
);

has 'max_discards' => (
  is      => 'rw',
  #default => sub { return 1 },
  clearer => 1,
);

has 'min_discards' => (
  is      => 'rw',
  #default => sub { return 1 },
  clearer => 1,
);

sub discard {
  my ( $self, $cards ) = @_;
  my $chair = $self->action;
  return $self->discard_chair( $chair, $cards );
}

sub draw {
  my ( $self, $cards ) = @_;
  my $map = {};
  for my $card (@$cards) {
    my $new_card = shift @{ $self->dealer->deal_down(1) };
    $self->add_discard($self->chairs->[ $self->action ]->cards->[ $card ]);
    $self->chairs->[ $self->action ]->cards->[ $card ] = $new_card;
    $map->{$card} = $new_card->rank . $new_card->suit; 
  }
  return $map;
}

sub discard_chair {
  my ( $self, $chair, $cards ) = @_;
  my $chair_ref = $self->chairs->[$chair];
  my @hole_cards = grep { defined $chair_ref->cards->[$_] } @$cards;
  for my $i (@hole_cards) {
    $self->add_discard( $chair_ref->cards->[$i] );
    #push @{ $self->dealer->deck->discards }, $chair_ref->cards->[$i]->clone;
    undef $chair_ref->cards->[$i];
  }
  $chair_ref->cards( [ grep { defined } @{ $chair_ref->cards } ] );
  return [@hole_cards];
}

sub add_discard {
  my ( $self, $card ) = @_;
  push @{ $self->dealer->deck->discards}, $card;
}

1;
