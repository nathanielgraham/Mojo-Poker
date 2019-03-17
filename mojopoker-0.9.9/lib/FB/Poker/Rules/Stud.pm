package FB::Poker::Rules::Stud;
use Moo::Role;

with 'FB::Poker::Bring';

sub _build_ante {
  my $self = shift;
  return $self->small_bet ? $self->small_bet / 4 : undef;
}

sub _build_no_blinds {
  return 1;
}

sub round1 {
  my $self = shift;
  $self->post_all;
  $self->deal_down_all(2);
  $self->deal_up_all(1);
  $self->valid_act( { map { $_ => 1 } qw(bring) } );
  $self->action( $self->worst_show );
  if (defined $self->action && !$self->sp_flag) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => $handle . ' brings it in.' } );
  }
  $self->set_next_round(2);
}

sub round2 {
  my $self = shift;
  $self->bring_done(1);
  $self->deal_up_all(1);
  $self->action( $self->best_show )
    if defined $self->action;
  if (defined $self->action && !$self->sp_flag) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => 'Fourth street.' } );
    $self->chat->write( 'd', { message => $handle . ' starts the betting.' } );
  }
  $self->set_next_round(3);
}

sub round3 {
  my $self = shift;
  $self->small_bet($self->small_bet * 2) if $self->limit eq 'FL';
  $self->deal_up_all(1);
  $self->action( $self->best_show )
    if defined $self->action;
  if (defined $self->action && !$self->sp_flag) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => 'Fifth street.' } );
    $self->chat->write( 'd', { message => $handle . ' starts the betting.' } );
  }
  $self->set_next_round(4);
}

sub round4 {
  my $self = shift;
  $self->deal_up_all(1);
  $self->action( $self->best_show )
    if defined $self->action;
  if (defined $self->action && !$self->sp_flag) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => 'Sixth street.' } );
    $self->chat->write( 'd', { message => $handle . ' starts the betting.' } );
  }
  $self->set_next_round(5);
}

sub round5 {
  my $self = shift;
  $self->deal_down_all(1);
  $self->action( $self->best_show )
    if defined $self->action;
  if (defined $self->action && !$self->sp_flag) {
    my $handle = $self->chairs->[ $self->action ]->player->handle;
    $self->chat->write( 'd', { message => 'Seventh street.' } );
    $self->chat->write( 'd', { message => $handle . ' starts the betting.' } );
  }
  $self->set_next_round(6);
}

sub round6 {
  my $self = shift;
  $self->chat->write( 'd', { message => 'Game over.' } );
  $self->small_bet($self->small_bet / 2) if $self->limit eq 'FL';
  $self->end_game;
}

1;
