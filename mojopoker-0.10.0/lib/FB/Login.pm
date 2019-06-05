package FB::Login;
use EV;
use Moo;

has 'timeout' => (
  is       => 'rw',
);

sub logout {}

has 'id' => (
  is       => 'rw',
  required => 1,
);

has 'db' => ( is => 'rw', );

has 'user_id' => (
  is        => 'rw',
  predicate => 'has_user_id',
);

has 'first_req_time' => (
  is        => 'rw',
  default => sub { return time },
);

has 'last_req_time' => (
  is        => 'rw',
  default => sub { return time },
);

has 'first_err_time' => (
  is        => 'rw',
);

has 'last_err_time' => (
  is        => 'rw',
);

has 'strikes' => (
  is        => 'rw',
  default => sub { return 0 },
);

sub req_error {
  my $self = shift;
  $self->strikes($self->strikes + 1);
  $self->last_err_time(time);
  $self->first_err_time($self->last_err_time)
    unless $self->first_err_time;
}

has 'block' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'level' => (
  is      => 'rw',
  default => sub { return 1 },
);

has 'bookmark' => ( is => 'rw', );

has 'ring_play' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'tour_play' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'play_chips' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_chips',
);

sub _build_chips {
  return {};
}

has 'play_invested' => (
  is      => 'rw',
  isa     => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_invested',
);

sub _build_invested {
  return {};
}

sub fetch_all_chips {
  my $self = shift;
  return $self->play_chips unless $self->user_id;
  my %chip;
  my $sql = <<SQL;
SELECT director_id, chips 
FROM user_chips 
WHERE user_id = ? 
SQL
  my $sth = $self->db->prepare($sql);
  $sth->execute( $self->user_id );
  while ( my ( $d, $c ) = $sth->fetchrow_array ) {
    $chip{$d} = $c;
  }
  return {%chip};
}

sub fetch_all_invested {
  my $self = shift;
  return $self->play_invested unless $self->user_id;
  my %chip;
  my $sql = <<SQL;
SELECT director_id, invested 
FROM user_chips 
WHERE user_id = ? 
SQL
  my $sth = $self->db->prepare($sql);
  $sth->execute( $self->user_id );
  while ( my ( $d, $c ) = $sth->fetchrow_array ) {
    $chip{$d} = $c;
  }
  return {%chip};
}

sub fetch_chips {
  my ( $self, $did ) = @_;
  unless ( $self->user_id ) {
    $self->play_chips->{$did} |= 0;
    return $self->play_chips->{$did};
  }
  my $sql = <<SQL;
SELECT chips 
FROM user_chips 
WHERE user_id = ?
AND director_id = ?
SQL
  my $sth = $self->db->prepare($sql);
  $sth->execute( $self->user_id, $did );
  my $chips = $sth->fetchrow_array || 0;
  return $chips;
}

sub _create_chips {
  my ( $self, $did ) = @_;
  my $user_id = $self->user_id;
  my $sql     = <<SQL;
REPLACE INTO user_chips (user_id, director_id, chips, invested) 
VALUES ($user_id, $did, (SELECT chips 
FROM user_chips 
WHERE user_id = $user_id
AND director_id = $did), (SELECT invested
FROM user_chips 
WHERE user_id = $user_id
AND director_id = $did))
SQL
  return $self->db->do($sql);
}

sub debit_chips {
  my ( $self, $did, $chips ) = @_;
  unless ( $self->user_id ) {
    $self->play_chips->{$did} |= 0;
    $self->play_chips->{$did} -= $chips;
    return $self->play_chips->{$did};
  }
  $self->_create_chips($did);
  my $user_id = $self->user_id;
  my $sql     = <<SQL;
UPDATE user_chips 
SET chips = chips - $chips 
WHERE user_id = $user_id 
AND director_id = $did
SQL
  return $self->db->do($sql);
}

sub credit_chips {
  my ( $self, $did, $chips ) = @_;
  unless ( $self->user_id ) {
    $self->play_chips->{$did} |= 0;
    $self->play_chips->{$did} += $chips;
    return $self->play_chips->{$did};
  }
  $self->_create_chips($did);
  my $user_id = $self->user_id;
  my $sql     = <<SQL;
UPDATE user_chips 
SET chips = chips + $chips 
WHERE user_id = $user_id 
AND director_id = $did
SQL
  return $self->db->do($sql);
}

sub credit_invested {
  my ( $self, $did, $chips ) = @_;
  unless ( $self->user_id ) {
    $self->play_invested->{$did} |= 0;
    $self->play_invested->{$did} += $chips;
    return $self->play_invested->{$did};
  }
  $self->_create_chips($did);
  my $user_id = $self->user_id;
  my $sql     = <<SQL;
UPDATE user_chips 
SET invested = invested + $chips 
WHERE user_id = $user_id 
AND director_id = $did
SQL
  return $self->db->do($sql);
}

has 'username' => (
  is        => 'rw',
  clearer   => 1,
  predicate => 'has_username',
);
has 'password'   => ( is => 'rw', );
has 'email'      => ( is => 'rw', );
has 'birthday'   => ( is => 'rw', );
has 'reg_date'   => ( is => 'rw', );
has 'last_visit' => ( is => 'rw', );
has 'handle'     => (
  is        => 'rw',
  clearer   => 1,
  predicate => 'has_handle',
);

sub remote_address { return }

sub BUILD {
  my $self = shift;
  $self->username('Guest' . $self->id) unless $self->has_username;
  $self->handle($self->username) unless $self->has_handle;
}

1;

