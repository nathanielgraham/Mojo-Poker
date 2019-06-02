package FB::Poker::Rules::Pineapple;
use Moo::Role;

#with 'FB::Poker::Draw';

# pre-flop betting round
sub round1 {
  my $self = shift;
  $self->auto_play_ok(0);
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(3);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->bb) );
  $self->chat->write( 'd', { message => 'pre-flop betting round.' } );
  $self->set_next_round(2);
}

# discard round
sub round2 {
  my $self = shift;
  $self->max_discards(1);
  $self->min_discards(1);
  $self->valid_act( { map { $_ => 1 } qw(discard fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'discard one card.' } );
  }
  $self->set_next_round(3);
}

# flop
sub round3 {
  my $self = shift;
  $self->auto_play_ok(1);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'Here comes the flop.' } );
  }
  $self->deal_community(3);
  $self->set_next_round(4);
}

# turn
sub round4 {
  my $self = shift;
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'Turn.' } );
  }
  $self->deal_community(1);
  $self->set_next_round(5);
}

# river
sub round5 {
  my $self = shift;
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'River.' } );
  }
  $self->deal_community(1);
  $self->set_next_round(6);
}

# end
sub round6 {
  my $self = shift;
  $self->chat->write( 'd', { message => 'Game over.' } );
  $self->end_game;
}

1;
