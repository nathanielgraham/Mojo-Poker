package FB::Poker::Rules::TripleDraw;
use Moo::Role;

# setup and first betting round
sub round1 {
  my $self = shift;
  $self->auto_play_ok(0);
  #$self->move_button;
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(5);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action($self->next_chair($self->bb));
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'first betting round.' } );
  }
  $self->set_next_round(2);
}

# first drawing round 
sub round2 {
  my $self = shift;
  $self->max_draws(5);
  $self->min_draws(1);
  $self->valid_act( { map { $_ => 1 } qw(check draw fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;

  unless ($self->sp_flag) {
    my $msg = 'first drawing round (up to 3 cards).';
    $self->chat->write( 'd', { message => $msg } );
  }
  $self->set_next_round(3);
}

# second betting round
sub round3 {
  my $self = shift;
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'second betting round.' } );
  }
  $self->set_next_round(4);
}

# second drawing round 
sub round4 {
  my $self = shift;
  $self->max_draws(5);
  $self->min_draws(1);
  $self->valid_act( { map { $_ => 1 } qw(check draw fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    my $msg = 'second drawing round (up to 3 cards).';
    $self->chat->write( 'd', { message => $msg } );
  }
  $self->set_next_round(5);
}

# third betting round
sub round5 {
  my $self = shift;
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'third betting round.' } );
  }
  $self->set_next_round(6);
}

# third drawing round 
sub round6 {
  my $self = shift;
  $self->max_draws(5);
  $self->min_draws(1);
  $self->valid_act( { map { $_ => 1 } qw(check draw fold) } );
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    my $msg = 'third drawing round (up to 3 cards).';
    $self->chat->write( 'd', { message => $msg } );
  }
  $self->set_next_round(7);
}

# fourth betting round
sub round7 {
  my $self = shift;
  $self->auto_play_ok(1);
  $self->valid_act( { map { $_ => 1 } qw(bet check fold) } );
  $self->action( $self->next_chair($self->button) )
    if defined $self->action;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'final betting round.' } );
  }
  $self->set_next_round(8);
}

# showdown
sub round8 {
  my $self = shift;
  $self->end_game;
}

1;
