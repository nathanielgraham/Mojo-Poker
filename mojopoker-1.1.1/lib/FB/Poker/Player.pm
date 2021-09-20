package FB::Poker::Player;
use Moo;

has 'player_id' => (
  is      => 'rw',
);

has 'time_bank' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'time_bank_start' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'handle' => (
  is        => 'rw',
  clearer => 1,
  lazy => 1,
  predicate => 'has_handle',
  builder => '_build_handle',
);

sub _build_handle {
 my $self = shift;
 return $self->login->user->handle ? $self->login->user->handle : $self->login->user->username;
}

has 'payout' => (
  is      => 'rw',
  predicate => 'has_payout',
  default => sub { return 0 },
);

has 'status' => (
  is      => 'rw',
);

has 'chair' => (
  is      => 'rw',
);

has 'table_id' => (
  is      => 'rw',
);

has 'chips' => (
  is      => 'rw',
  predicate => 'has_chips',
  builder => '_build_chips',
);

sub _build_chips {
  return 0;
}

has 'login' => (
  is      => 'rw',
  isa     => sub { die "Not a FB::Login!" unless $_[0]->isa('FB::Login'); },
  predicate => 'has_login',
);

has 'wait_bb' => (
  is      => 'rw',
  default => sub { return 1 },
  clearer => 1,
);

has 'auto_rebuy' => (
  is      => 'rw',
  clearer => 1,
);

has 'auto_muck' => (
  is      => 'rw',
  clearer => 1,
  default => sub { return 1 },
);

has 'sit_out' => (
  is  => 'rw',
  clearer => 1,
);

has 'timesup_count' => (
  is  => 'rw',
  default => sub { return 0 },
);

sub clone {
  my $self = shift;
  bless {%$self, @_}, ref $self;
}

1;
