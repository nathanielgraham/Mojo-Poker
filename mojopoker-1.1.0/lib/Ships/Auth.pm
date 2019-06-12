package Ships::Auth;
use Mojo::Base 'Mojolicious::Controller';

sub block {
  my $self = shift;
  my $address = $self->tx->remote_address;
  return 1 if $address eq '127.0.0.1';
  return 0 if exists $self->app->address_block->{$address};
  my $now = time;
  if ($self->app->address_info->{$address}->{prev_req_time}) {
    if ($now - $self->app->address_info->{$address}->{prev_req_time} < 2) {
      $self->app->address_info->{$address}->{fast_req_time} = $now
        unless $self->app->address_info->{$address}->{fast_req_time};
      my $fast = $self->app->address_info->{$address}->{fast_req_time};
      my $strikes = ++$self->app->address_info->{$address}->{strikes};
      my $sec = $now - $fast || 1;
      my $sec_per_strike = $sec / $strikes;
      #print "SEC: $sec, STRIKES: $strikes, AVG: $sec_per_strike, NOW: $now, FAST: $fast\n";
      if ($sec_per_strike < .1 && $strikes > 20) {
        # blocked
        $self->app->address_block->{$address}++;
        return 0;
      }
    }
    else {
      undef $self->app->address_info->{$address}->{fast_req_time};
      undef $self->app->address_info->{$address}->{strikes};
    }
  }
  $self->app->address_info->{$address}->{prev_req_time} = $now;
  return 1;
}

1;

