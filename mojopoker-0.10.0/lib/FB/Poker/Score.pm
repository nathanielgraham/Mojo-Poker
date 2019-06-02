package FB::Poker::Score;
use Moo;

has 'hands' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has '_hand_lookup' => (
  is       => 'rw',
  isa      => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
  init_arg => undef,
);

has '_hand_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { {} },
);

has '_rank_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
);

sub _build_rank_map {
  my $self = shift;
  $self->_rank_map(
    {
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
      'A' => '14',
    }
  );
}

has '_suit_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
);

sub _build_suit_map {
  my $self = shift;
  $self->_suit_map(
    {
      'c' => '01',
      'd' => '02',
      'h' => '03',
      's' => '04',
    }
  );
}


sub hand_name {
  my ( $self, $score ) = @_;
  for my $key ( sort { $b <=> $a } keys %{ $self->_hand_map } ) {
    if ( $score > $key ) {
      return $self->_hand_map->{$key};
    }
  }
}

sub rank_val {
  my ( $self, $rank ) = @_;
  return $self->_rank_map->{$rank};
}

sub suit_val {
  my ( $self, $suit ) = @_;
  return $self->_suit_map->{$suit};
}

sub hand_score {
  my ( $self, $hand ) = @_;
  return $self->_hand_lookup->{$hand};
}

sub score {
  my ( $self, $cards ) = @_;
  return $self->hand_score( $self->stringify_cards($cards) );
}

sub stringify_cards {
  my ( $self, $cards ) = @_;
  my %suit;
  for my $card (@$cards) {
    $suit{ $card->suit }++;
  }
  my $flat = join( '',
    sort { $b <=> $a }
    map { sprintf( "%02d", $self->rank_val( $_->rank ) ) } @$cards );
  $flat .= 's' if scalar keys %suit == 1;
  return $flat;
}

sub _build_hand_lookup {
  my $self = shift;
  my %look;
  for my $i ( 0 .. $#{ $self->hands } ) {
    $look{ $self->hands->[$i] } = $i;
  }
  $self->_hand_lookup( \%look );
}

sub _build_hands { }

sub BUILD {
  my $self = shift;
  $self->_build_hands;
  $self->_build_hand_lookup;
  $self->_build_rank_map;
  $self->_build_suit_map;
}

1;
