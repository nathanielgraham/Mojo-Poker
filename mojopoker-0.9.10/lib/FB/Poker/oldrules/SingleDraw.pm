package FB::Poker::Rules::SingleDraw;
use Moo::Role;

#with 'FB::Poker::Draw';

# setup and first betting round
sub round1 {
  my $self = shift;
  #$self->move_button;
  $self->auto_play_ok(0);
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(5);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->bb) );
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'first betting round.' } );
  }
  $self->set_next_round(2);
}

# drawing round 
sub round2 {
  my $self = shift;
  $self->max_draws(5);
  $self->min_draws(0);
  $self->valid_act( { map { $_ => 1 } qw(check draw fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'drawing round' } );
  }
  $self->set_next_round(3);
}

# second betting round
sub round3 {
  my $self = shift;
  $self->auto_play_ok(1);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'second betting round.' } );
  }
  $self->set_next_round(4);
}

# showdown
sub round4 {
  my $self = shift;
  $self->end_game;
}

#sub _build_new_chair {
#  return FB::Poker::Chair::Draw->new;
#}

1;
