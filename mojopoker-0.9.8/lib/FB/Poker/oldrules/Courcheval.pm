package FB::Poker::Rules::Courcheval;
use Moo::Role;

with 'FB::Poker::Rules::Omaha';

sub round1 {
  my $self = shift;
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(5);
  $self->deal_community(1);
  $self->valid_act( { map { $_ => 1 } qw(fold check bet) } );
  $self->action( $self->next_chair($self->bb) );

  $self->chat->write( 'd', { message => 'pre-flop betting round.' } );
  $self->set_next_round(2);
}

sub round2 {
  my $self = shift;
  $self->small_bet($self->small_bet * 2) if $self->limit eq 'FL';
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'Here comes the flop:' } );
  }
  $self->deal_community(2);
  $self->action( $self->next_chair( $self->button) )
    if defined $self->action;
  $self->set_next_round(3);
}

1;
