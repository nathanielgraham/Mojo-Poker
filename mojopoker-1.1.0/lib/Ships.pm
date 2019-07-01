package Ships;
use Mojo::Base 'Mojolicious';
use lib 'perl5';
use FB;

has 'address_block' => sub {
  return {};
};

has 'address_info' => sub {
  return {};
};

has facebook_app_id => sub {
   return '431502190982449';
};

has facebook_secret => sub {
   return 'dee98631a540b933dd8e2f46e1ab9512';
};

has fb => sub {
  my $self = shift;
  return FB->new(
    address_block => $self->app->address_block,
    facebook_secret => $self->facebook_secret,
  );
};

# This method will run once at server start
sub startup {
  my $self = shift;

  $ENV{LIBEV_FLAGS} = 4;

  # cookie setup
  #$self->sessions->cookie_name('ships');
  #$self->sessions->default_expiration(315360000); #10 years
  #$self->sessions->secure(1);  # only send cookies over SSL
  #$self->secret('g)ue(ss# %m4e &i@f y25o*u c*69an');
  #$self->plugin('PODRenderer');

  # Router
  my $r = $self->routes;
  # swap next line for the one after for custom DOS protection
  #my $b = $r->under('/')->to( controller => 'auth', action => 'block' );
  my $b = $r->under( sub { return 1 } ); # don't block anyone
  $b->websocket('/websocket')->to( controller => 'websocket', action => 'service' );
  $b->route('/')->to( controller => 'main', action => 'default' );
  #$r->route('/book/:bookmark')->to( controller => 'main', action => 'book' );
  $r->route('/privacy')->to( controller => 'main', action => 'privacy' );
  $r->route('/terms')->to( controller => 'main', action => 'terms' );
  $r->route('/leaderboard')->to( controller => 'main', action => 'leader' );
  $r->route('/deletion')->to( controller => 'main', action => 'deletion' );
  $r->post('/delete')->to(controller => 'main', action => 'delete');
  $r->route('*')->to(cb => sub { shift->redirect_to('/') });
}

1;
