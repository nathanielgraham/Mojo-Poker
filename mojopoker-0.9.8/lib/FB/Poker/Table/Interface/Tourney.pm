package FB::Poker::Table::Interface::Tourney;
use Moo::Role;
use Scalar::Util qw(weaken);

with 'FB::Poker::Table::Interface';

sub _build_type {
  return 't';
}

has 'tournament' => (
  is => 'rw',
  isa =>
    sub { die "Not a tournament!" unless $_[0]->isa('FB::Poker::Tournament') },
  required  => 1,
  predicate => 'has_tournament',
);

after 'end_game' => sub {
  my $self = shift;
  $self->tournament->end_table_hand($self);
};

#before 'new_game' => sub {
#  my $self = shift;
#  $self->tournament->new_table_hand($self);
#};

after 'sit' => sub {
  my ( $self, $chair, $player ) = @_;
  #$self->watch_list->{ $player->login->id } = $player->login;
  my $res = $self->watch($player->login);
  #return unless $res->{success};
  $res->{tour_id} = $self->tournament->tour_id;
  $player->login->send([ 'join_tour_tbl', $res ]);

};

after '_unseat_chair' => sub {
  my ( $self, $chair_id, $login ) = @_;

};

sub _notify_watch {
  my ( $self, $response ) = @_;
  $response->[1]->{table_id} = $self->table_id;
  $response->[1]->{tour_id}  = $self->tournament->tour_id;
  for my $log ( values %{ $self->watch_list } ) {
    $log->send($response);
  }
}

around '_watch' => sub {
  my ( $orig, $self, $login ) = @_;
  my $rv = $orig->( $self, $login );
  $rv->{tour_id} = $self->tour_id;
  return $rv;
};

around '_unwatch' => sub {
  my ( $orig, $self, $login ) = @_;
  my $rv = $orig->( $self, $login );
  $rv->{tour_id} = $self->tour_id;
  return $rv;
};

1;

