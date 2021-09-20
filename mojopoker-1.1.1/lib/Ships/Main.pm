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

sub leader {
    my $self = shift;
    $self->render(
        template => 'leader',
        format   => 'html',
        handler  => 'ep',
    );
}

sub delete {
    my $self = shift;
    my $signed_request = $self->param('signed_request');
    my $return = {url => undef, confirmation_code => undef};
    my $status_url = "https://mojopoker.xyz/deletion?id=";
    my $secret = $self->app->facebook_secret;
    my ($encoded_sig, $payload) = split(/\./, $signed_request, 2);
    unless ($encoded_sig && $payload) {
       $self->render(json => $return);
       return;
    }
    my $data = j(decode_base64($payload));
    my $expected_sig = encode_base64(hmac_sha256($payload, $secret), "");
    $expected_sig =~ tr/\/+/_-/;
    $expected_sig =~ s/=//;

    if ($encoded_sig eq $expected_sig && exists $data->{user_id}) {
      #verified; okay to do something with $data
       my $read  = <<SQL;
SELECT id, bookmark
FROM user
WHERE facebook_id = $data->{user_id}
SQL
       my ($id, $bookmark) = $self->app->fb->db->dbh->selectrow_array($read);

       unless ($id && $bookmark) {
          $self->render(json => $return);
          return;
       }

       my $delete = <<SQL;
UPDATE user SET facebook_id = NULL, facebook_deleted = CURRENT_TIMESTAMP
WHERE id = $id
SQL
       $self->app->fb->db->dbh->do($delete);
       $status_url .= $bookmark;
       $return->{url} = $status_url;
       $return->{confirmation_code} = $bookmark;

    }
    $self->render(json => $return);
}

sub deletion {
    my $self = shift;
    my $id = $self->param('id');
   
    return unless $id;

    my $sql  = <<SQL;
SELECT facebook_deleted 
FROM user
WHERE bookmark = '$id'
SQL

    my $deleted = $self->app->fb->db->dbh->selectrow_array($sql);

    return unless $deleted;

    $self->stash(
       deleted => $deleted,
    );

    $self->render(
        template => 'deletion',
        format   => 'html',
        handler  => 'ep',
    );
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

