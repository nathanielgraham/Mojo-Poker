package FB::Poker::Rules::Holdem;
use Moo::Role;
use Data::Dumper;

sub round1 {
  my $self = shift;
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(2);
  $self->valid_act( { map { $_ => 1 } qw(fold check bet) } );
  $self->chat->write( 'd', { message => 'Pre-flop betting round.' } );
  $self->action( $self->next_chair($self->bb) );
  $self->set_next_round(2);
}

sub round2 {
  my $self = shift;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'Here comes the flop:' } );
  }
  $self->deal_community(3);
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->set_next_round(3);
}

sub round3 {
  my $self = shift;
  $self->small_bet($self->small_bet * 2) if $self->limit eq 'FL';
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'Turn:' } );
  }
  $self->deal_community(1);
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->set_next_round(4);
}

sub round4 {
  my $self = shift;
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'River:' } );
  }
  $self->deal_community(1);
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->set_next_round(5);
}

sub round5 {
  my $self = shift;
  $self->chat->write( 'd', { message => 'Game over.' } );
  $self->action( undef );
  $self->small_bet($self->small_bet / 2) if $self->limit eq 'FL';
  $self->end_game;
}

1;
