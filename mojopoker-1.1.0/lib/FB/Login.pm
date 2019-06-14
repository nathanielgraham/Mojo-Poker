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

has 'block' => (
  is  => 'rw',
  isa => sub { die "Not a hash!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { return {} },
);

has 'user' => (
  is        => 'rw',
  predicate => 'has_user',
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

sub remote_address { return }

1;

