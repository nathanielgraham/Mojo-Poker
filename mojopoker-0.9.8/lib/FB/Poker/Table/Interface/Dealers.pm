package FB::Poker::Table::Interface::Dealers;
use Moo::Role;

with 'FB::Poker::Table::Interface::Ring';

sub _build_type {
  return 'r';
}

#sub auto_start_code {
#  my $self = shift;
#  if ($self->game_over && $self->auto_start_count >= $self->auto_start) {
#    $self->new_game;
#  }
#}

sub new_game {
  my $self = shift;

  # reset table
  $self->reset_table;

  # reset chairs
  for my $chair ( @{ $self->chairs } ) {
    $chair->new_game_reset;
  }

  $self->game_count( $self->game_count + 1 );

  # shuffle
  $self->dealer->shuffle_deck;
  #$self->move_button;
  #print "ACTION1: " . $self->action . "\n";
  print "BUTTON1: " . $self->button . "\n";
  $self->action( $self->next_chair($self->button) );
  print "ACTION2: " . $self->action . "\n";
  print "BUTTON2: " . $self->button . "\n";
  $self->valid_act( { map { $_ => 1 } qw(choice) } );

  $self->_notify_watch(
    [ 'notify_dealers_choice', {
      dealer => $self->action,
    } ] 
  );

  # game setup
  #$self->next_round(1);
  #$self->begin_new_round;
}

1;

