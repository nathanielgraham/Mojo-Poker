package FB::Poker::Tournament::Freezeout;
use Moo;

extends 'FB::Poker::Tournament';

after 'end_table_hand' => sub {
  my ( $self, $table ) = @_;

  # disolve table if possible
  my @seated = map { $_->player } grep { $_->has_player } @{ $table->chairs };
  my $open_count =
    $self->open_chair_count - scalar grep { !$_->has_player }
    @{ $table->chairs };

  if ( $open_count >= scalar @seated
    || scalar @seated < $self->reseat_limit )
  {
    push @{ $self->unseated }, @seated;
    $self->remove_table( $table->table_id );
  }
  else {
    $self->balance_table($table);
  }

  $self->seat_extra;

  # start new game
  $table->auto_start_game( $table->new_game_delay );

};

1;
