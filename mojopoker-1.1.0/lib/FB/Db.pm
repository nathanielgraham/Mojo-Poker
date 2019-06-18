package FB::Db;

use Moo;
use FB::User;

use DBI;
use SQL::Abstract;
use Digest::SHA qw(hmac_sha1_hex);

#use Data::Dumper;

has 'secret' => ( 
   is => 'rw', 
   default => sub { return 'g)ue(ss# %m4e &i@f y25o*u c*69an' }, 
);

has 'dbh' => ( 
   is => 'rw', 
   builder => '_build_dbh',
);

sub _build_dbh {
    return DBI->connect( "dbi:SQLite:dbname=/opt/mojopoker/db/fb.db", "", "" );
}

has 'sql' => (
    is => 'rw',
    isa =>
      sub { die "Not a SQL::Abstract!" unless $_[0]->isa('SQL::Abstract') },
    builder => '_build_sql',
);

sub _build_sql {
    return SQL::Abstract->new;
}

sub new_user {
   my ($self, $opts) = @_;
   my ( $stmt, @bind ) = $self->sql->insert( 'user', $opts );
   my $sth = $self->dbh->prepare($stmt);
   $sth->execute(@bind);

   $opts->{id} = $self->dbh->last_insert_id( "", "", "", "" );
   $opts->{reg_date} = time;
   $opts->{level}    = 2;
   $opts->{handle}   = $opts->{username} if $opts->{username};
   $opts->{bookmark} = hmac_sha1_hex( $opts->{id}, $self->secret );
   return if $self->dbh->err;  
   my $user = FB::User->new(%$opts);
   return $user;
}

sub fetch_user {
    my ( $self, $opts ) = @_;
    my ( $stmt, @bind ) = $self->sql->select( 'user', '*', $opts );
    my $sth = $self->dbh->prepare($stmt);
    $sth->execute(@bind);
    my $href = $sth->fetchrow_hashref;
    return unless $href;
    $href->{user_id} = $href->{id};
    return FB::User->new(%$href);
    #return $user;
}

sub update_user {
    my ( $self, $opts, $id ) = @_;
    $opts->{last_visit} = time;
    my ( $stmt, @bind ) =
      $self->sql->update( 'user', $opts, { id => $id } );
    my $sth = $self->dbh->prepare($stmt);
    $sth->execute(@bind);
    return $self->dbh->err ? undef : 1;  
}

sub fetch_leaders {
    my $self = shift;
    my $sql  = <<SQL;
SELECT username, ROUND((chips - invested)*1.00 / invested, 2) * 100 AS profit, chips
FROM user
WHERE id != 1 
ORDER BY profit DESC
LIMIT 20
SQL
    my $ary_ref = $self->dbh->selectall_arrayref($sql);
    return $ary_ref;
}

sub reset_leaders {
    my $self = shift;

    my $sql = <<SQL;
UPDATE user 
SET chips = 200, invested = 200 
SQL
    return $self->dbh->do($sql);

}

sub debit_chips {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET chips = chips - $chips 
WHERE id = $user_id
SQL
    return $self->dbh->do($sql);
}

sub credit_chips {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET chips = chips + $chips 
WHERE id = $user_id 
SQL
    return $self->dbh->do($sql);
}

sub fetch_chips {
    my ( $self, $user_id ) = @_;
    my $sql = <<SQL;
SELECT chips 
FROM user 
WHERE id = ?
SQL

  my $sth = $self->dbh->prepare($sql);
  $sth->execute( $user_id );
  my $chips = $sth->fetchrow_array || 0;
  return $chips;
}

sub credit_invested {
    my ( $self, $user_id, $chips ) = @_;
    my $sql = <<SQL;
UPDATE user 
SET invested = invested + $chips
WHERE id = $user_id 
SQL
    return $self->dbh->do($sql);
}

1;
