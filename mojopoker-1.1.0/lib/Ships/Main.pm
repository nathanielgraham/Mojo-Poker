package Ships::Main;
use Mojo::Base 'Mojolicious::Controller';
use MIME::Base64;
use Mojo::JSON qw(j);
use Digest::SHA qw(hmac_sha256);


sub default {
    my $self = shift;

    # upgrade websocket scheme to wss
    my $url = $self->url_for('websocket')->to_abs;
    $url->scheme('wss') if $self->req->headers->header('X-Forwarded-For');
    my $opts = 'ws: "' . $url->to_abs . '"';

    $self->stash( 
       opts => $opts,
       facebook_app_id => $self->app->facebook_app_id, 
    );

    $self->render(
        template => 'main',
        format   => 'html',
        handler  => 'ep',
    );
}

sub terms {
    my $self = shift;
    $self->render(
        template => 'terms',
        format   => 'html',
        handler  => 'ep',
    );
}

sub privacy {
    my $self = shift;
    $self->render(
        template => 'privacy',
        format   => 'html',
        handler  => 'ep',
    );
}

sub delete {
    my $self = shift;
    my $signed_request = $self->param('signed_request');
    #my $user_id = $self->param('user_id');

=pod
    my $del  = <<SQL;
UPDATE deleted_date = CURRENT_TIMESTAMP 
FROM facebook_user
WHERE facebook_user_id = $user_id
SQL

    $self->fb->db->do($sql);

    my $read  = <<SQL;
SELECT user_id
FROM facebook_user
WHERE facebook_user_id = $user_id
SQL
    my $uid = $self->fb->db->selectrow_array;
=cut

    my $status_url = "https://mojopoker.xyz/deleted?code=";
    my $secret = $self->app->facebook_secret;
    my ($encoded_sig, $payload) = split(/\./, $signed_request, 2);
    my $data = j(decode_base64($payload));
    my $expected_sig = encode_base64(hmac_sha256($payload, $secret), "");
    $expected_sig =~ tr/\/+/_-/;
    $expected_sig =~ s/=//;

    if ($encoded_sig eq $expected_sig) {
      #verified; okay to do something with $data
    }

    $self->render(json => {url => $status_url, confirmation_code => $data->{user_id}});
}

sub book {
    my $self = shift;
    my $bookmark = param('bookmark');
    my $url = $self->url_for('websocket')->to_abs;
    $url->scheme('wss') if $self->req->headers->header('X-Forwarded-For');
    my $opts = 'ws: "' . $url->to_abs . '", bookmark: "' . $bookmark . '"';

    $self->stash(
       opts => $opts,
       facebook_app_id => $self->app->facebook_app_id,
    );

    $self->render(
        template => 'main',
        format   => 'html',
        handler  => 'ep',
    );
}

1;

