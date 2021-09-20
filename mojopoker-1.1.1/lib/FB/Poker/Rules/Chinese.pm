package FB::Poker::Rules::Chinese;
use Algorithm::Combinatorics 'combinations';
use FB::Poker::Eval::Chinese;
use FB::Poker::Chair::Chinese;
use Moo::Role;
use Data::Dumper;

sub _build_new_chair {
  return FB::Poker::Chair::Chinese->new;
}

has 'chinese_eval' => (
  is       => 'rw',
  isa      => sub { die "Not an Eval!\n" unless $_[0]->isa('FB::Poker::Eval') },
  required => 1,
);

has 'chips_per_point' => (
  is      => 'rw',
  default => sub { 1 },
);

#has 'chinese_winners' => (
#  is  => 'rw',
#  isa => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
#  default => sub { [] },
#);

#has 'chinese_hash' => (
#  is  => 'rw',
#  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
#  default => sub { {} },
#);

#has 'chinese_mult' => (
#  is      => 'rw',
#  builder => '_build_chinese_mult',
#);

sub _build_chinese_mult {
  return 1;
}

#before 'score' => sub {
#  my $self = shift;
#  $self->hi_eval->community_cards( $self->community_cards );
#};

after 'score_chair' => sub {
  my ( $self, $chair ) = @_;
  my $best =
    $self->chinese_eval->best_hand( $chair->front, $chair->middle, $chair->back,
    );
  if ( defined $best ) {
    $chair->chinese_hand($best);

    #push @{ $self->hi_hash->{ $chair->hi_hand->{score} } }, $chair;
  }
};

after 'score' => sub {
  my $self          = shift;
  my $active_chairs = [ grep { $_->is_in_hand } @{ $self->chairs } ];
  my @matches       = combinations( $active_chairs, 2 );
  for my $match (@matches) {
    my $p0_points = 0;
    my $p1_points = 0;
    my $p0_hand   = $match->[0]->chinese_hand;
    my $p1_hand   = $match->[1]->chinese_hand;
    if ( $p0_hand && $p1_hand ) {
      if ( $p0_hand->{front}->{score} > $p1_hand->{front}->{score} ) {
        $p0_points += 1;
      }
      elsif ( $p0_hand->{front}->{score} < $p1_hand->{front}->{score} ) {
        $p1_points += 1;
      }
      if ( $p0_hand->{middle}->{score} > $p1_hand->{middle}->{score} ) {
        $p0_points += 1;
      }
      elsif ( $p0_hand->{middle}->{score} < $p1_hand->{middle}->{score} ) {
        $p1_points += 1;
      }
      if ( $p0_hand->{back}->{score} > $p1_hand->{back}->{score} ) {
        $p0_points += 1;
      }
      elsif ( $p0_hand->{back}->{score} < $p1_hand->{back}->{score} ) {
        $p1_points += 1;
      }
    }
    elsif ($p0_hand) {
      $p0_points += 6;
    }
    elsif ($p1_hand) {
      $p1_points += 6;
    }

    # royalties
    if ($p0_hand) {
      $p0_points +=
        ( $p0_hand->{front}->{royalty} +
          $p0_hand->{middle}->{royalty} +
          $p0_hand->{back}->{royalty} );
    }
    if ($p1_hand) {
      $p1_points +=
        ( $p1_hand->{front}->{royalty} +
          $p1_hand->{middle}->{royalty} +
          $p1_hand->{back}->{royalty} );
    }
    print "match: chair"
      . $match->[0]->index . " vs. "
      . $match->[1]->index . "\n";
    print "p0: $p0_points\n";
    print "p1: $p1_points\n";
  }
};

after 'reset_table' => sub {
  my $self = shift;

  #$self->hi_winners( [] );
  #$self->hi_hash( {} );
};

after 'payout' => sub {
  my $self = shift;

  #$self->high_payout;
};

#sub high_payout {
#  my $self = shift;
#  $self->pay_hash( $self->hi_hash, $self->hi_winners, $self->hi_mult );
#}

sub deal_chin {
  my $self = shift;
  for my $chair ( grep { $_->is_in_hand } @{ $self->chairs } ) {
    push @{ $chair->back },   @{ $self->dealer->deal_down(5) };
    push @{ $chair->middle }, @{ $self->dealer->deal_down(5) };
    push @{ $chair->front },  @{ $self->dealer->deal_down(3) };
  }
}

sub move {
  my ( $self, $map ) = @_;
  my $chair = $self->chairs->[ $self->action ];

  while (my($k, $v) = each( %$map)) {
    my $row = $v->[0];
    my $index = $v->[1];
    if ( $row == 0 && $index < 3 && $chair->cards->[$k] && !defined $chair->front->[ $index ] ) {
      $chair->front->[ $index ] = $chair->cards->[ $k ];
      $chair->cards->[ $k ] = undef;
    }
    elsif ( $row == 1 && $index < 6 && $chair->cards->[$k] && !defined $chair->middle->[ $index ] ) {
      $chair->middle->[ $index ] = $chair->cards->[ $k ];
      $chair->cards->[ $k ] = undef;
    }
    elsif ( $row == 2 && $index < 6 && $chair->cards->[$k] && !defined $chair->back->[ $index ] ) {
      $chair->back->[ $index ] = $chair->cards->[ $k ];
      $chair->cards->[ $k ] = undef;
    }
    else {
      return;
    }
  }
  return $map;
}

sub escrow {
  my $self = shift;
}

sub round1 {
  my $self = shift;
  $self->escrow;
  #$self->move_button;
  $self->deal_down_all(5);
  $self->valid_act( { map { $_ => 1 } qw(move) } );
  $self->action( $self->next_chair( $self->button ) );
  $self->set_next_round(2);
}

sub round2 {
  my $self = shift;
  $self->deal_down_all(3);
  $self->set_next_round(3);
}

sub round3 {
  my $self = shift;
  $self->deal_down_all(3);
  $self->set_next_round(4);
}

sub round4 {
  my $self = shift;
  $self->deal_down_all(3);
  $self->set_next_round(5);
}

sub round5 {
  my $self = shift;
  $self->deal_down_all(3);
  $self->set_next_round(5);
}

sub round6 {
  my $self = shift;
  $self->end_game;
}

1;
