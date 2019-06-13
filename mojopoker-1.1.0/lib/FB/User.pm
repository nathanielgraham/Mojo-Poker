package FB::User;
use EV;
use Moo;

has 'db' => ( is => 'rw', );

has 'id' => (
  is       => 'rw',
  required => 1,
);

has 'facebook_id' => (
  predicate => 'has_facebook_id',
  is        => 'rw',
);

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

sub fetch_chips {
  my $self = shift;
  my $sql = <<SQL;
SELECT chips 
FROM user 
WHERE id = ?
SQL
  my $sth = $self->db->prepare($sql);
  $sth->execute( $self->id );
  my $chips = $sth->fetchrow_array || 0;
  return $chips;
}

sub debit_chips {
  my ( $self, $chips ) = @_;
  my $id = $self->id;
  my $sql     = <<SQL;
UPDATE user 
SET chips = chips - $chips 
WHERE id = $id 
SQL
  return $self->db->do($sql);
}

sub credit_chips {
  my ( $self, $chips ) = @_;
  my $id = $self->id;
  my $sql     = <<SQL;
UPDATE user 
SET chips = chips + $chips 
WHERE id = $id 
SQL
  return $self->db->do($sql);
}

sub credit_invested {
  my ( $self, $chips ) = @_;
  my $id = $self->id;
  my $sql     = <<SQL;
UPDATE user 
SET invested = invested + $chips 
WHERE id = $id 
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

sub BUILD {
  my $self = shift;
  $self->username('Guest' . $self->id) unless $self->has_username;
  $self->handle($self->username) unless $self->has_handle;
}

1;

