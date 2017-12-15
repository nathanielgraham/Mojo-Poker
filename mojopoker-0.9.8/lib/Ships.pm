package Ships;
use Mojo::Base 'Mojolicious';
use lib 'perl5';
use FB;

has 'address_info' => sub {
  return {};
};

has 'address_block' => sub {
  return {};
};

has fb => sub {
  my $self = shift;
  return FB->new(
    address_block => $self->app->address_block,
  );
};

# This method will run once at server start
sub startup {
  my $self = shift;

  # force https in production
  $self->hook(before_dispatch => sub {
    my $c = shift;
    if ($c->req->url->base->scheme eq 'http') {
      $c->req->url->base->scheme('https');
      $c->req->url->base->port(443);
      $c->redirect_to($c->req->url->to_abs);
    }
  }) if $ENV{MOJO_MODE} && $ENV{MOJO_MODE} eq 'production';

  $ENV{LIBEV_FLAGS} = 4;

  # cookie setup
  #$self->sessions->cookie_name('ships');
  #$self->sessions->default_expiration(315360000); #10 years
  #$self->sessions->secure(1);  # only send cookies over SSL
  #$self->secret('g)ue(ss# %m4e &i@f y25o*u c*69an');
  #$self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;
  my $b = $r->under('/')->to( controller => 'auth', action => 'block' );
  $b->websocket('/websocket')->to( controller => 'websocket', action => 'service' );
  #$b->route('/')->to(cb => sub { shift->reply->static('index.html') });
  $b->route('/')->to( controller => 'main', action => 'default' );
  $r->route('*')->to(cb => sub { shift->redirect_to('/') });
}

1;
