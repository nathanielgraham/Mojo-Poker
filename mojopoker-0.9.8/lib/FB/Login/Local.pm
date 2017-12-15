package FB::Login::Local;
use Moo;
use Mojo::JSON qw(j);
use feature qw(say);

extends 'FB::Login';

sub send {
  my ($self, $href) = @_;
  say(j($href));
}

sub logout {
  my $self = shift;
  say("logout id: $self->id");
}

1;

