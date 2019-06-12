package FB::Poker::Score::Low27;
#use Data::Dumper;
use Moo;

extends 'FB::Poker::Score::High';

after _build_hands => sub {
  my $self = shift;
  my %map;
  $self->hands( [ reverse @{ $self->hands } ] );

  my @names =
    map  { $self->_hand_map->{$_} }
    sort { $a <=> $b } keys %{ $self->_hand_map };
  my @keys = sort { $a <=> $b } keys %{ $self->_hand_map };
  my $lowest = shift @keys;
  for my $key (@keys) {
    $map{ $#{ $self->hands } - $key } = shift @names;
  }
  $map{ $lowest } = pop @names;
  $self->_hand_map( \%map );
  #print Dumper(\%map);
};

# straights
# Aces always play high in the 27 scoring system
# e.g., A2345 is NOT a straight
sub _build_straights {
  return [
    '0605040302', '0706050403', '0807060504', '0908070605', '1009080706',
    '1110090807', '1211100908', '1312111009', '1413121110',
  ];
}

1;
