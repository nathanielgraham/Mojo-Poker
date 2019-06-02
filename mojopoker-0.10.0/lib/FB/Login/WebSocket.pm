package FB::Login::WebSocket;
use Moo;
use Mojo::JSON qw(j);
#use Mojo::JSON qw(encode_json);

extends 'FB::Login';

has 'websocket' => (
  is => 'rw',
);

sub remote_address { shift->websocket->remote_address }

sub send {
  my ($self, $href) = @_;
  #$self->websocket->send(encode_json($href));
  $self->websocket->send(j($href));
}

sub logout { shift->websocket->finish }

sub BUILD {
  my $self = shift;
}

1;

