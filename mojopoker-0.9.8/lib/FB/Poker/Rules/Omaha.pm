package FB::Poker::Rules::Omaha;
use Moo::Role;

with 'FB::Poker::Rules::Holdem';

sub round1 {
  my $self = shift;
  $self->post_all;
  $self->post_now;
  $self->deal_down_all(4);
  $self->valid_act( { map { $_ => 1 } qw(fold check bet) } );
  $self->action( $self->next_chair($self->bb) );
  unless ($self->sp_flag) {
    $self->chat->write( 'd', { message => 'pre-flop betting round.' } );
  }
  $self->set_next_round(2);
}

1;
