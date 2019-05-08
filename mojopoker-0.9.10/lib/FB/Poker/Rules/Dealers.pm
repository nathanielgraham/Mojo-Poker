package FB::Poker::Rules::Dealers;
use Moo::Role;
use Data::Dumper;

sub round1 {
  my $self = shift;
  $self->chat->write( 'd', { message => 'Game over.' } );
  $self->end_game;
}

1;
