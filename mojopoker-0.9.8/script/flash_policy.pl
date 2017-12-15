#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  $c->render(template => 'policy', format => 'xml');
};

app->config(
  hypnotoad => {
    listen => [ 'http://*:843' ],
  }
);

__DATA__
@@ policy.xml.ep
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<site-control permitted-cross-domain-policies="master-only"/>
<allow-access-from domain="*" to-ports="*" secure="false"/>
</cross-domain-policy>
