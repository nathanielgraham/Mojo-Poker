package FB::Poker::Rules::CrazyPine;
use Moo::Role;
use Data::Dumper;

#with 'FB::Poker::Draw';
#with 'FB::Poker::Rules::Pineapple';

# pre-flop betting round
sub round1 {
  my $self = shift;
  $self->auto_play_ok(0);
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(3);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->bb) );
  $self->chat->write( 'd', { message => 'pre-flop betting round.' } )
    unless ($self->sp_flag);
  $self->set_next_round(2);
}

# flop and discard
sub round2 {
  my $self = shift;
  $self->max_discards(1);
  $self->min_discards(1);
  $self->valid_act( { map { $_ => 1 } qw(discard fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->chat->write( 'd', { message => 'Here comes the flop.' } )
    unless ($self->sp_flag);
  $self->deal_community(3);
  $self->chat->write( 'd', { message => 'discard one.' } )
    unless ($self->sp_flag);
  $self->set_next_round(3);
}

# betting round
sub round3 {
  my $self = shift;
  $self->auto_play_ok(1);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->chat->write( 'd', { message => 'post-flop betting round.' } )
    unless ($self->sp_flag);
  $self->set_next_round(4);
}

# turn
sub round4 {
  my $self = shift;
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->chat->write( 'd', { message => 'Turn.' } )
    unless ($self->sp_flag);
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
