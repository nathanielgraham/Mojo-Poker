package Ships::Websocket;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON 'j';

sub service {
  my $self = shift;

  #$self->inactivity_timeout(0);
  #$self->tx->with_compression;
  #Mojo::IOLoop->stream( $self->tx->connection )->timeout(0);
  if ($self->app->address_block->{$self->tx->remote_address}) {
    # blocked
    #$self->tx->finish;
    #return;
  }

  my $login = $self->app->fb->_guest_login( { websocket => $self->tx } );

  $self->on(
    message => sub {
      my ( $self, $msg ) = @_;
      my $now = time;
      my $address = $self->tx->remote_address;
      if ($self->app->address_info->{$address}->{prev_req_time}) { 
        if ($now - $self->app->address_info->{$address}->{prev_req_time} < 2) {
          $self->app->address_info->{$address}->{fast_req_time} = $now 
            unless $self->app->address_info->{$address}->{fast_req_time};
          my $fast = $self->app->address_info->{$address}->{fast_req_time};
          my $strikes = ++$self->app->address_info->{$address}->{strikes};
          my $sec = $now - $fast || 1;
          my $sec_per_strike = $sec / $strikes; 
          #print "SEC: $sec, STRIKES: $strikes, AVG: $sec_per_strike, NOW: $now, FAST: $fast\n";
          #if (($sec_per_strike < .2 && $strikes > 10) || $strikes > 30 ) {
          if ($sec_per_strike < .1 && $strikes > 20) {
            # block
            #$self->app->address_block->{$address}++;
            $self->app->fb->_logout($login, { message => 'Try again later.'});
            $self->tx->finish;
            #print "TOO MANY STRIKES\n";
            return;
          }
        }
        else {
          undef $self->app->address_info->{$address}->{fast_req_time};
          undef $self->app->address_info->{$address}->{strikes};
        }
      }
      #$self->app->address_info->{$address}->{prev_req_time} = $now 
      #  unless $address eq '127.0.0.1'; 
      #$self->app->fb->request( $login, $msg );
      my $aref = eval { j($msg) }; 
      if ($@) {
        $login->req_error;
        $login->send( [ 'malformed_json', { message => $@ } ] );
      }
      else {
        $self->app->fb->request( $login, $aref );
      }
      #$self->app->fb->request( $login, \$msg );
    }
  );

  # Disconnected
  $self->on(
    finish => sub {
      my $self = shift;
      #cleanup now
      $self->app->fb->_cleanup($login);

#      if ($login->user_id) {
        # Cleanup in 30 minutes
#      }
#      else {
#        $self->app->fb->_cleanup($login);
#      }
      $self->app->log->debug("Logout " . $login->id);
    }
  );
}

1;
