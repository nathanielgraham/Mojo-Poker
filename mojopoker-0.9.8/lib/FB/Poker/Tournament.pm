package FB::Poker::Tournament;
use Moo;
use FB::Poker::Player;
use FB::Poker::Table::Maker;
use List::MoreUtils qw(first_value);
use POSIX qw(ceil floor);
use List::Util qw(max);
use Scalar::Util qw(weaken);
use Data::Dumper;

has 'level_timer' => ( is => 'rw', );

has 'tour_class' => (
  is       => 'rw',
  required => 1,
);

has 'lobby_watch' => (
  is       => 'rw',
  isa      => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  required => 1,
);

sub _notify_lobby {
  my ( $self, $res ) = @_;
  $res->[1]->{tour_id} = $self->tour_id;
  for my $log ( values %{ $self->lobby_watch } ) {
    $log->send($res);
  }
}

has 'watch_list' => (
  is      => 'rw',
  isa     => sub { die "Not an hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

sub _notify_watch {
  my ( $self, $res ) = @_;
  $res->[1]->{tour_id} = $self->tour_id;
  for my $log ( values %{ $self->watch_list } ) {
    $log->send($res);
  }
}

sub unwatch {
  my ( $self, $login ) = @_;
  return $self->_unwatch($login);
}

sub _unwatch {
  my ( $self, $login ) = @_;
  delete $self->watch_list->{ $login->id };
  return {
    tour_id => $self->tour_id,
    success => 1,
  };
}

sub watch {
  my ( $self, $login ) = @_;
  return $self->_watch($login);
}

sub _watch {
  my ( $self, $login ) = @_;
  $self->watch_list->{ $login->id } = $login;
  return {
    #%{ $self->summary },
    tour_id  => $self->tour_id,
    success  => 1,
    state    => $self->status,
    start_time => $self->start_time,
    end_time => $self->end_time,
    prizes   => $self->prizes,
    add_plrs => $self->_player_info([values %{ $self->registered }]),
  };
}

sub summary {
  my $self = shift;
  return {
    tour_id     => $self->tour_id,
    director_id => $self->director_id,
    game_class  => $self->game_class,
    limit       => $self->limit,
    tour_class  => $self->tour_class,
    enrolled    => scalar keys %{ $self->registered },
    state       => $self->status,
    start_time  => $self->start_time,
    end_time    => $self->end_time,
    buy_in      => $self->buy_in,
    entry_fee   => $self->entry_fee,
  };
}

has 'table_maker' => (
  is       => 'rw',
  required => 1,
);

has 'director_id' => (
  is       => 'rw',
  required => 1,
);

has 'game_class' => (
  is       => 'rw',
  required => 1,
);

has 'limit' => (
  is      => 'rw',
  default => sub { return 'NL' },
);

has 'chair_count' => (
  is      => 'rw',
  default => sub { 6 },
);

has 'player_count' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'table_count' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'table_event' => ( is => 'rw', );

has 'tour_id' => ( is => 'rw', );

has 'type' => (
  is      => 'rw',
  default => sub { 1 },
);

# closed 0, registering 1, late-reg 2, playing 3, complete 4
has 'status' => (
  is      => 'rw',
  default => sub { 0 },
  trigger => sub {
    my $self = shift;
    $self->_notify_lobby( [ 'notify_lt_update', { state => $self->status } ] );
    $self->_notify_watch(
      [ 'tour_update', { state => $self->status } ]
    );
  }
);

has 'start_time' => ( 
  is => 'rw', 
  trigger => sub {
    my $self = shift;
    $self->_set_start_timer;
  }
);

has 'start_timer' => ( is => 'rw', );

sub _set_start_timer {
  my $self = shift;
  return unless $self->start_time;
  my $t = $self->start_time - time;
  return unless $t > 0;
  $self->start_timer(
    EV::timer $t,
    0,
    sub {
      $self->start_tour;
    }
  );
}

has 'end_time' => (
  is        => 'rw',
  predicate => 'has_end_time',
);

has 'open_time' => ( is => 'rw', );

#has 'game_args' => (
#  is  => 'rw',
#  isa => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
#  default => sub { {} },
#);

has 'private' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'chat_ok' => (
  is      => 'rw',
  default => sub { 1 },
);

has 'seats_per_table' => (
  is      => 'rw',
  default => sub { 6 },
);

has 'tables' => (
  is        => 'rw',
  isa       => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  predicate => 'has_tables',
  builder   => '_build_tables',
);

sub _build_tables {
  return {};
}

has 'max_players' => (
  is      => 'rw',
  default => sub { 180 },
);

has 'min_players' => (
  is      => 'rw',
  default => sub { 2 },
);

has 'start_when_full' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'remove_no_shows' => (
  is      => 'rw',
  default => sub { 1 },
);

has 'turn_clock' => (
  is      => 'rw',
  default => sub { 15 },
);

has 'time_bank' => (
  is      => 'rw',
  default => sub { 60 },
);

has 'level_duration' => (
  is      => 'rw',
  default => sub { 300 },    #seconds
);

has 'level' => (
  is        => 'rw',
  default   => sub { 1 },
  predicate => 'has_levels',
);

has 'level_info' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_level_info',
);

sub _build_level_info {
  return {
    1  => { sb => 15,     bb => 30,     ante => 0 },
    2  => { sb => 25,     bb => 50,     ante => 0 },
    3  => { sb => 50,     bb => 100,    ante => 0 },
    4  => { sb => 75,     bb => 150,    ante => 0 },
    5  => { sb => 100,    bb => 200,    ante => 0 },
    6  => { sb => 100,    bb => 200,    ante => 25 },
    7  => { sb => 200,    bb => 400,    ante => 25 },
    8  => { sb => 300,    bb => 600,    ante => 50 },
    9  => { sb => 400,    bb => 800,    ante => 50 },
    10 => { sb => 600,    bb => 1200,   ante => 75 },
    11 => { sb => 800,    bb => 1600,   ante => 75 },
    12 => { sb => 1000,   bb => 2000,   ante => 100 },
    13 => { sb => 1500,   bb => 3000,   ante => 150 },
    14 => { sb => 2000,   bb => 4000,   ante => 200 },
    15 => { sb => 3000,   bb => 6000,   ante => 300 },
    16 => { sb => 4000,   bb => 8000,   ante => 400 },
    17 => { sb => 6000,   bb => 12000,  ante => 600 },
    18 => { sb => 8000,   bb => 16000,  ante => 800 },
    19 => { sb => 10000,  bb => 20000,  ante => 1000 },
    20 => { sb => 15000,  bb => 30000,  ante => 1500 },
    21 => { sb => 20000,  bb => 40000,  ante => 2000 },
    22 => { sb => 25000,  bb => 50000,  ante => 2500 },
    23 => { sb => 35000,  bb => 70000,  ante => 3500 },
    24 => { sb => 45000,  bb => 90000,  ante => 4500 },
    25 => { sb => 55000,  bb => 11000,  ante => 5500 },
    26 => { sb => 70000,  bb => 14000,  ante => 7000 },
    27 => { sb => 85000,  bb => 17000,  ante => 8500 },
    28 => { sb => 100000, bb => 200000, ante => 10000 },
    29 => { sb => 125000, bb => 250000, ante => 12500 },
  };
}

has 'max_level' => ( is => 'rw', );

has 'late_reg' => (
  is        => 'rw',
  predicate => 'has_late_reg',
  default   => sub { 300 },      #seconds
);

has 'start_chips' => (
  is      => 'rw',
  default => sub { 1500 },
);

#has 'buy_in_prize' => (
#  is      => 'rw',
#  default => sub { 0 },
#);

has 'entry_fee' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'buy_in' => (
  is      => 'rw',
  builder => '_build_buy_in',
);

sub _build_buy_in {
  return 0;
}

has 'payout_struct' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_payout_struct',
);

sub _build_payout_struct {
  return {
    2  => [qw(100)],
    5  => [qw(65 35)],
    8  => [qw(50 30 20)],
    11 => [qw(45 28 17 10)],
    21 => [qw(36 23 15 11 8 7)],
    41 => [qw(30 20 14 10 8 7 6 5)],
    71 => [qw(29 18 12.5 10 8 6.5 5.5 4.5 3.5 2.5)],
  };
}

has 'guaranteed' => (
  is        => 'rw',
  default   => sub { 0 },
  predicate => 'has_guaranteed',
);

#has 'prizes' => (
#  is        => 'rw',
#  isa       => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
#  predicate => 'has_prizes',
#);

has 'prize_fund' => ( is => 'rw', );

has 'reseat_limit' => (
  is      => 'rw',
  default => sub { 2 },
);

has 'unseated' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_unseated',
);

sub _build_unseated {
  return [];
}

has 'registered' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_registered',
);

sub _build_registered {
  return {};
}

sub _player_info {
  my ($self, $plrs) = @_;
  return {
    map {
      $_->player_id => {
        handle   => $_->login->handle,
        #table_id => $_->table_id,
        chips    => $_->chips,
        status   => $_->status,
      }
    } @$plrs
    #} values %{ $self->registered }
  };

  #while (my($k,$v) = each %{ $self->tables }) {
  #}
}

sub _fetch_regs {
  my ( $self, $login ) = @_;
  my @regs;
  for my $p ( values %{ $self->registered } ) {
    if ( $p->login->id == $login->id ) {
      push @regs, $p;
    }
  }
  return [@regs];
}

sub _fetch_ips {
  my ( $self, $login ) = @_;
  my @ips;
  for my $p ( values %{ $self->registered } ) {
    if ( $p->login->remote_address eq $login->remote_address ) {
      push @ips, $p;
    }
  }
  return [@ips];
}

sub register {
  my ( $self, $login ) = @_;
  return { success => 0, message => 'Registration closed' }
    unless $self->status == 1
    || ( $self->status == 2
    && ( time < $self->start_time + $self->late_reg ) );

# status: 1 = registered, 2 = unseated, 3 = seated, 4 = done
#my @regs = @{ $self->_fetch_ips($login) }; # unique ip addresses
#my @regs = @{ $self->_fetch_regs($login) };
#if (scalar @regs) {
#  return { success => 0, tour_id => $self->tour_id, message => 'Already registered' };
#}

  if ( $self->buy_in + $self->entry_fee >
    $login->fetch_chips( $self->director_id ) )
  {
    return { success => 0, message => 'Not enough chips' };
  }

  $login->debit_chips( $self->director_id, $self->buy_in + $self->entry_fee );
  $self->prize_fund( $self->prize_fund + $self->buy_in );

  my $player = FB::Poker::Player->new(
    login  => $login,
    chips  => $self->start_chips,
    status => 1,                    # registered
  );

  $self->player_count( $self->player_count + 1 );
  $player->player_id( $self->player_count );
  $self->registered->{ $player->player_id } = $player;
  $login->tour_play->{ $self->tour_id }     = 1;
  $self->_notify_lobby(
    [ 'notify_lt_update', { enrolled => scalar keys %{ $self->registered } } ]
  );

  #new
  $self->_notify_watch(
    [ 'tour_update', { add_plrs => $self->_player_info([$player]) } ]
  );

  if ( $self->start_when_full
    && scalar keys %{ $self->registered } == $self->max_players )
  {    #
    $self->start_tour;
  }
  elsif ( $self->status == 2 ) {    # late reg
    $player->status(2);             # unseated
    $player->table_id(undef);       # unseated
    push @{ $self->unseated }, $player;
  }
  return {
    success   => 1,
    player_id => $player->player_id,
    login_id  => $login->id,
    tour_id   => $self->tour_id
  };
}

sub prizes {
  my $self      = shift;
  my $reg_count = scalar keys %{ $self->registered };
  my $prize_key = first_value { $_ >= $reg_count }
  sort { $a <=> $b } keys %{ $self->payout_struct };
  return [ map { $_ * $self->prize_fund / 100 }
      @{ $self->payout_struct->{$prize_key} } ];
}

sub unregister {
  my ( $self, $login ) = @_;
  my @pids;
  my $ret = {
    success  => 0,
    tour_id  => $self->tour_id,
    login_id => $login->id
  };
  my @regs = @{ $self->_fetch_regs($login) };
  if ( scalar @regs ) {
    for my $reg (@regs) {
      $login->credit_chips( $self->director_id,
        $self->buy_in + $self->entry_fee );
      $self->prize_fund( $self->prize_fund - $self->buy_in );
      delete $self->registered->{ $reg->player_id };
      push @pids, $reg->player_id;
    }
    $ret->{success}    = 1;
    $ret->{player_ids} = [@pids];
  }
  delete $login->tour_play->{ $self->tour_id };

  $self->_notify_lobby(
    [ 'notify_lt_update', { enrolled => scalar keys %{ $self->registered } } ]
  );
  $self->_notify_watch(
    [ 'tour_update', { del_plrs => [ @pids ] } ]
  );
  return $ret;
}

sub add_table {
  my ($self, $table_id) = @_;
  #my $table_id = $self->table_count( $self->table_count + 1 );

  #my $args = $self->game_args;
  my $args = {
    tour_id     => $self->tour_id,
    table_id    => $table_id,
    director_id => $self->director_id,
    game_class  => $self->game_class,
    limit       => $self->limit,
    chair_count => $self->chair_count,
    tournament  => $self,
    #tournament  => weaken ($self),
    big_blind   => $self->level_info->{ $self->level }->{bb},
    small_blind => $self->level_info->{ $self->level }->{sb},
    ante        => $self->level_info->{ $self->level }->{ante},
  };
  my $table = $self->table_maker->tour_table($args);
  $self->tables->{$table_id} = $table;
}

sub remove_table {
  my ( $self, $table_id ) = @_;
  delete $self->tables->{$table_id};
  $self->_notify_watch(
    [ 'tour_update', { del_tbls => [ $table_id ] } ]
  );
}

sub open_tour {
  my $self = shift;
  if ( $self->status ) {
    return { success => 0 };
  }
  else {
    $self->status(1);    # open for registration
    return { success => 1 };
  }
}

sub start_tour {
  my $self      = shift;
  my $reg_count = scalar keys %{ $self->registered };
  return { success => 0, message => 'Player min not met' }
    unless $reg_count >= $self->min_players;

  #print Dumper( $self->prizes );
  $self->status(4);      #started

  $self->unseated( [ values %{ $self->registered } ] );
  $self->add_tables;

  #print Dumper($self->tables);

  $self->balance_tables;
  $self->seat_extra;
  $self->start_time(time);
  $self->update_level;

  $self->level_timer(
    EV::timer $self->level_duration,
    $self->level_duration,
    sub {
      if ( $self->level >= $self->max_level ) {
        $self->level_timer(undef);
        return;
      }
      $self->level( $self->level + 1 );
      $self->update_level;
    }
  );

  for my $t ( values %{ $self->tables } ) {
    $self->_update_table($t);
  }

  while ( my ( $k, $table ) = each %{ $self->tables } ) {
    $table->auto_start(2);
    $table->new_game;
    print "TABLE: $k: " . $table->game_class . "\n";
    for my $chair ( grep { $_->has_player } @{ $table->chairs } ) {
      print "CHAIR: " . $chair->index . " " . $chair->player->chips . "\n";
    }
  }
  return { success => 1 };
}

sub add_tables {
  my $self    = shift;
  my $orphans = scalar @{ $self->unseated } - $self->open_chair_count;
  return unless $orphans > 0;
  my $table_count = ceil( $orphans / $self->seats_per_table );
  #for my $id ( 1 .. $table_count ) {
  #my @tbl_ids;
  for ( 1 .. $table_count ) {
    my $table_id = $self->table_count( $self->table_count + 1 );
    #push @tbl_ids, $table_id;
    $self->add_table($table_id);
  }
  #$self->_notify_watch(
  #  [ 'tour_update', { add_tbls => [ @tbl_ids ] } ]
  #);
}

sub seated_chairs {
  my $self = shift;
  my @chairs;
  for my $table ( values %{ $self->tables } ) {
    push @chairs, grep { $_->has_player } @{ $table->chairs };
  }
  return [@chairs];
}

sub open_chair_count {
  my $self        = shift;
  my $chair_count = 0;
  for my $table ( values %{ $self->tables } ) {
    $chair_count += scalar grep { !$_->has_player } @{ $table->chairs };
  }
  return $chair_count;
}

sub seat_extra {
  my $self         = shift;
  my @extra_chairs = @{ $self->extra_chairs };

  #while (my $player = shift @{ $self->unseated }) {
  #while ( my ( $table, $chair ) = @{ shift @extra_chairs } ) {
  while ( my $aref = shift @extra_chairs ) {
    my ( $table, $chair ) = @{$aref};
    my $player = shift @{ $self->unseated } or last;

    #my ($table, $chair) = @{ shift @extra_chairs or last };
    $player->status(3);                       #seated
    $player->table_id( $table->table_id );    #seated
    $table->sit( $chair->index, $player );

    #$chair->sit($player);

    #$table->seated_list->{ $player->login->id } = $chair->index;
  }
}

sub balance_tables {
  my $self = shift;
  for my $table ( values %{ $self->tables } ) {
    $self->balance_table($table);
  }
}

sub balance_table {
  my ( $self, $table ) = @_;
  my $avg           = $self->avg_per_table;
  my @seated_chairs = grep { $_->has_player } @{ $table->chairs };
  my $seated_count  = scalar @seated_chairs;

  # seat new players if table below average
  if ( $seated_count < floor($avg) ) {
    my $diff = floor($avg) - $seated_count;
    my @unseated_chairs = grep { !$_->has_player } @{ $table->chairs };
    for ( 1 .. $diff ) {
      my $chair  = shift @unseated_chairs     or last;
      my $player = shift @{ $self->unseated } or last;
      $player->status(3);    #seated
      $player->table_id( $table->table_id );
      $table->sit( $chair->index, $player );

      #$chair->sit($player);
      #$table->seated_list->{ $player->login->id } = $chair->index;
    }
  }

  # reseat players if table above average
  elsif ( $seated_count > ceil($avg) ) {
    my @extra_chairs = @{ $self->extra_chairs };
    my $diff         = $seated_count - ceil($avg);
    for ( 1 .. $diff ) {
      my $chair = shift @seated_chairs or last;
      my $player = $chair->player;

      #while ( my ( $new_table, $new_chair ) = @{ shift @extra_chairs } ) {
      while ( my $aref = shift @extra_chairs ) {
        my ( $new_table, $new_chair ) = @{$aref};
        $table->_unseat_chair( $chair->index, $player->login );
        $new_table->sit( $new_chair->index, $player );

        #$new_chair->sit($player);

        #$new_table->seated_list->{ $player->login->id } = $new_chair->index;
      }
    }
  }
}

sub extra_chairs {
  my $self = shift;
  my @extra_chairs;
TABLE:
  for my $table ( values %{ $self->tables } ) {
    my @unseated_chairs = grep        { !$_->has_player } @{ $table->chairs };
    my $seated_count    = scalar grep { $_->has_player } @{ $table->chairs };
    my $diff = ceil( $self->avg_per_table ) - $seated_count;
    for ( 1 .. $diff ) {
      my $chair = shift @unseated_chairs or next TABLE;
      push @extra_chairs, [ $table, $chair ];
    }
  }
  return [@extra_chairs];
}

sub avg_per_table {
  my $self = shift;
  my $player_count =
    scalar @{ $self->unseated } + scalar @{ $self->seated_chairs };
  return $player_count / scalar keys %{ $self->tables };
}

sub player_out {
  my ( $self, $player ) = @_;
  $self->payout($player);
}

sub payout {
  my ( $self, $player ) = @_;
  my ($place) = scalar grep { $_->status == 4 } values %{ $self->registered };
  my $prize = $self->prizes->[$place];
  $player->status(4);          # out
  $player->table_id(undef);    # out
  if ( defined $prize ) {
    $self->player->login->credit_chips( $self->director_id, $prize );
  }
}

#sub new_table_hand {
#  my ( $self, $table ) = @_;
#}

sub end_table_hand {
  my ( $self, $table ) = @_;

  # remove players
  for my $chair ( grep { $_->has_player } @{ $table->chairs } ) {
    if ( $chair->player->chips <= 0 ) {
      $self->player_out( $chair->player );
      $chair->reset;
    }
  }
  $self->_update_table($table);
}

sub _update_table {
  my ($self, $table) = @_;
  my $plrs = $self->_player_info( [ map { $_->player } grep { $_->has_player } @{ $table->chairs } ] );
  my $msg = [ 'tour_update', { tbl_up => { table_id => $table->table_id, plrs => $plrs } } ];
  print Dumper($msg);
  $self->_notify_watch(
    $msg
    #[ 'tour_update', { tbl_up => { table_id => $table->table_id, plrs => $plrs } } ]
  );
}

sub update_level {
  my $self = shift;
  my %a    = (
    big_blind   => $self->level_info->{ $self->level }->{bb},
    small_blind => $self->level_info->{ $self->level }->{sb},
    ante        => $self->level_info->{ $self->level }->{ante},
  );

  #%{ $self->game_args } = (%{ $self->game_args }, %a);
  for my $table ( values %{ $self->tables } ) {
    %$table = ( %$table, %a );
  }
}

sub BUILD {
  my $self = shift;
  $self->max_level( max keys %{ $self->level_info } );
  $self->prize_fund( $self->guaranteed );
  $self->_set_start_timer;
}

#  my $cmd  = "use " . $self->game . "; 1";
#  $cmd =~ s/(.+)/$1/gee;
#  $self->game_args->{tournament} = $self;
#}

1;

__END__

thejap
add: late reg, open face, 
unimplemented: rebuy levels?, break

Type:             Freezeout
Game:             NL Hold'em
Private:          No
Player chat:      Yes
Observer chat:    Yes
Tables:           30
Seats per table:  8
Buy in:           1.90+0.10
Start at time:    Yes
Min players:      2
Start when full:  No
Start now votes:  No
Start with code:  No
Remove no-shows:  Yes
Prize bonus:      100 (guaranteed min)
Starting chips:   1500
Turn clock:       15 seconds
Time bank:        30 seconds
Level duration:   5 minutes
Rebuy levels:     0
Break:            No
