package Ships::Websocket;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON 'j';

sub service {
  my $self = shift;

  #$self->inactivity_timeout(0);
  #$self->tx->with_compression;

  my $login = $self->app->fb->_guest_login( { websocket => $self->tx } );
  $self->on(
    message => sub {
      my ( $self, $msg ) = @_;
      my $aref = eval { j($msg) }; 
      if ($@) {
        $login->req_error;
        $login->send( [ 'malformed_json', { message => $@ } ] );
      }
      else {
        $self->app->fb->request( $login, $aref );
      }
    }
  );

  # Disconnected
  $self->on(
    finish => sub {
      my $self = shift;
      #cleanup now
      $self->app->fb->_cleanup($login);
      $self->app->log->debug("Logout " . $login->id);
    }
  );
}

1;
