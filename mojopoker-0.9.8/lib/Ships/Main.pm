package Ships::Main;
use Mojo::Base 'Mojolicious::Controller';

sub default {
  my $self = shift;

  # Render template "example/welcome.html.ep" with message
  $self->render(
    template => 'main',
    format   => 'html',
    handler  => 'ep',
    #msg      => 'Hello World!',
  );
}

1;

