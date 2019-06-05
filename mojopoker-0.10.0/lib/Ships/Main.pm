package Ships::Main;
use Mojo::Base 'Mojolicious::Controller';

sub default {
    my $self = shift;

    # upgrade websocket scheme to wss
    my $url = $self->url_for('websocket')->to_abs;
    $url->scheme('wss') if $self->req->headers->header('X-Forwarded-For');
    $self->stash( furl => $url->to_abs );

    $self->render(
        template => 'main',
        format   => 'html',
        handler  => 'ep',
    );
}

1;

