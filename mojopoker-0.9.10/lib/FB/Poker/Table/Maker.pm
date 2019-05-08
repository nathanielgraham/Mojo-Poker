package FB::Poker::Table::Maker;
use Moo;

use FB::Chat;
use FB::Poker::Score::High;
use FB::Poker::Score::Bring::High;
use FB::Poker::Score::Bring::Low;
use FB::Poker::Score::Bring::Wild;
use FB::Poker::Score::Low8;
use FB::Poker::Score::Low27;
use FB::Poker::Score::LowA5;
use FB::Poker::Score::Badugi;
use FB::Poker::Score::Badugi27;
use FB::Poker::Score::Chinese;
use FB::Poker::Score::HighSuit;
use FB::Poker::Eval::Community;
use FB::Poker::Eval::Omaha;
use FB::Poker::Eval::Wild;
use FB::Poker::Eval::Badugi;
use FB::Poker::Eval::Badugi27;
use FB::Poker::Eval::HighSuit;
use FB::Poker::Eval::Bitch;
use FB::Poker::Eval::Chinese;
use FB::Poker::Table::Ring::Dealers;
use FB::Poker::Table::Ring::Holdem;
use FB::Poker::Table::Ring::Omaha;
use FB::Poker::Table::Ring::OmahaHiLo;
use FB::Poker::Table::Ring::OmahaFive;
use FB::Poker::Table::Ring::OmahaFiveHiLo;
use FB::Poker::Table::Ring::Stud;
use FB::Poker::Table::Ring::FTQ;
use FB::Poker::Table::Ring::Bitch;
use FB::Poker::Table::Ring::StudHiLo;
use FB::Poker::Table::Ring::Courcheval;
use FB::Poker::Table::Ring::CourchevalHiLo;
use FB::Poker::Table::Ring::Pineapple;
use FB::Poker::Table::Ring::CrazyPine;
use FB::Poker::Table::Ring::SingleDraw;
use FB::Poker::Table::Ring::TripleDraw;
use FB::Poker::Table::Ring::TripleDrawHiLo;
use FB::Poker::Table::Ring::Badugi;
use FB::Poker::Table::Tourney::Holdem;

#use FB::Poker::Tournament::Freezeout;
#use List::MoreUtils qw(first_value);
#use POSIX qw(ceil);
#use List::Util qw(max);
use Data::Dumper;

has 'lobby_watch' => (
  is       => 'rw',
  isa      => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  required => 1,
);

has 'dealer_choices' => (
  is      => 'rw',
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  builder => '_build_dealer_choices',
);

sub _build_dealer_choices {
  return {
    1  => { game_class => "holdem",         limit => "NL" },
    2  => { game_class => "holdemjokers",   limit => "FL" },
    3  => { game_class => "omaha",          limit => "PL" },
    4  => { game_class => "omahahilo",      limit => "PL" },
    5  => { game_class => "badugi",         limit => "NL" },
    6  => { game_class => "crazypine",      limit => "NL" },
    7  => { game_class => "omahafive",      limit => "PL" },
    8  => { game_class => "omahafivehilo",  limit => "PL" },
    9  => { game_class => "courcheval",     limit => "PL" },
    10 => { game_class => "courchevalhilo", limit => "PL" },
    11 => { game_class => "fivedraw",       limit => "NL" },
    12 => { game_class => "singledraw27",   limit => "NL" },
    13 => { game_class => "tripledraw27",   limit => "NL" },
    14 => { game_class => "badacey",        limit => "NL" },
    15 => { game_class => "badeucy",        limit => "NL" },
    16 => { game_class => "singledrawa5",   limit => "NL" },
    17 => { game_class => "tripledrawa5",   limit => "NL" },
    18 => { game_class => "pineapple",      limit => "NL" },
    19 => { game_class => "drawjokers",     limit => "NL" },
    20 => { game_class => "drawdeuces",     limit => "NL" },
    21 => {
      game_class => "sevenstud",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    22 => {
      game_class => "sevenstudhilo",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    23 => {
      game_class => "razz",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    24 => {
      game_class => "highchicago",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    25 => {
      game_class => "sevenstudjokers",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    26 => {
      game_class => "ftq",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
    27 => {
      game_class => "bitch",
      limit      => "FL",
      no_blinds  => 1,
      no_ante    => 0
    },
  };
}

has 'game_class' => (
  is  => 'rw',
  isa => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
);

sub _build_game_class {
  my $self = shift;
  return {
    dealers => {
      camel_class    => 'Dealers',
      dealer_choices => $self->dealer_choices,
      show_name   => "Dealer's Choice",
    },
    holdem => {
      camel_class => 'Holdem',
      hi_eval     => $self->eval_community_hi,
      show_name   => "Hold'em",
    },
    holdemjokers => {
      camel_class => 'Holdem',
      hi_eval     => $self->eval_wild_hi,
      wild_cards  => [qw(Joker1 Joker2)],
      show_name   => "Hold'em (Jokers Wild)",
    },
    omaha => {
      camel_class => 'Omaha',
      hi_eval     => $self->eval_omaha_hi,
      show_name   => "Omaha",
    },
    omahahilo => {
      camel_class => 'OmahaHiLo',
      hi_eval     => $self->eval_omaha_hi,
      low_eval    => $self->eval_omaha_low8,
      show_name   => "Omaha Hi-Lo",
    },
    omahafive => {
      camel_class => 'OmahaFive',
      hi_eval     => $self->eval_omaha_hi,
      show_name   => "Five Card Omaha",
    },
    omahafivehilo => {
      camel_class => 'OmahaFiveHiLo',
      hi_eval     => $self->eval_omaha_hi,
      low_eval    => $self->eval_omaha_low8,
      show_name   => "Five Card Omaha Hi-Lo",
    },
    sevenstud => {
      camel_class => 'Stud',
      hi_eval     => $self->eval_community_hi,
      bring_score => $self->score_bring_hi,
      show_name   => "Seven Card Stud",
    },
    sevenstudjokers => {
      camel_class => 'Stud',
      hi_eval     => $self->eval_wild_hi,
      bring_score => $self->score_bring_wild_hi,
      wild_cards  => [qw(Joker1 Joker2)],
      show_name   => "Seven Card Stud (Jokers Wild)",
    },
    sevenstudhilo => {
      camel_class => 'StudHiLo',
      hi_eval     => $self->eval_community_hi,
      low_eval    => $self->eval_community_low8,
      bring_score => $self->score_bring_hi,
      show_name   => "Seven Card Stud Hi-Lo",
    },
    highchicago => {
      camel_class => 'StudHiLo',
      hi_eval     => $self->eval_community_hi,
      low_eval    => $self->eval_highsuit,
      bring_score => $self->score_bring_hi,
      show_name   => "High Chicago",
    },
    razz => {
      camel_class => 'Stud',
      hi_eval     => $self->eval_community_lowa5,
      bring_score => $self->score_bring_lo,
      show_name   => "Razz",
    },
    ftq => {
      camel_class => 'FTQ',
      hi_eval     => $self->eval_wild_hi,
      bring_score => $self->score_bring_wild_hi,
      #wild_cards  => [qw(Joker1 Joker2)],
      show_name   => "Follow the Queen",
    },
    bitch => {
      camel_class => 'Bitch',
      hi_eval     => $self->eval_community_hi,
      low_eval    => $self->eval_bitch,
      bring_score => $self->score_bring_hi,
      #wild_cards  => [qw(Joker1 Joker2)],
      show_name   => "The Bitch",
    },
    courcheval => {
      camel_class => 'Courcheval',
      hi_eval     => $self->eval_community_hi,
      show_name   => "Courcheval",
    },
    courchevalhilo => {
      camel_class => 'CourchevalHiLo',
      hi_eval     => $self->eval_community_hi,
      low_eval    => $self->eval_omaha_low8,
      show_name   => "Courcheval Hi-Lo",
    },
    fivedraw => {
      camel_class => 'SingleDraw',
      hi_eval     => $self->eval_community_hi,
      show_name   => "Five Card Draw",
    },
    drawdeuces => {
      camel_class => 'SingleDraw',
      hi_eval     => $self->eval_wild_hi,
      wild_cards  => [qw(2s 2c 2d 2h)],
      show_name   => "Five Card Draw (Deuces Wild)",
    },
    drawjokers => {
      camel_class => 'SingleDraw',
      hi_eval     => $self->eval_wild_hi,
      wild_cards  => [qw(Joker1 Joker2)],
      show_name   => "Five Card Draw (Jokers Wild)",
    },
    singledraw27 => {
      camel_class => 'SingleDraw',
      hi_eval     => $self->eval_community_low27,
      show_name   => "2-7 Single Draw",
    },
    tripledraw27 => {
      camel_class => 'TripleDraw',
      hi_eval     => $self->eval_community_low27,
      show_name   => "2-7 Triple Draw",
    },
    singledrawa5 => {
      camel_class => 'SingleDraw',
      hi_eval     => $self->eval_community_lowa5,
      show_name   => "A-5 Single Draw",
    },
    tripledrawa5 => {
      camel_class => 'TripleDraw',
      hi_eval     => $self->eval_community_lowa5,
      show_name   => "A-5 Triple Draw",
    },
    pineapple => {
      camel_class => 'Pineapple',
      hi_eval     => $self->eval_community_hi,
      show_name   => "Pineapple",
    },
    crazypine => {
      camel_class => 'CrazyPine',
      hi_eval     => $self->eval_community_hi,
      show_name   => "Crazy Pineapple",
    },
    badugi => {
      camel_class => 'Badugi',
      hi_eval     => $self->eval_badugi,
      show_name   => "Badugi",
    },
    badacey => {
      camel_class => 'TripleDrawHiLo',
      hi_eval     => $self->eval_badugi,
      low_eval    => $self->eval_community_lowa5,
      show_name   => "Badacey",
    },
    badeucy => {
      camel_class => 'TripleDrawHiLo',
      hi_eval     => $self->eval_badugi27,
      low_eval    => $self->eval_community_low27,
      show_name   => "Badeucy",
    },
  };
}

has 'score_bring_hi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Bring object!"
      unless $_[0]->isa('FB::Poker::Score::Bring::High');
  },
  builder => '_build_score_bring_hi',
);

sub _build_score_bring_hi {
  return FB::Poker::Score::Bring::High->new;
}

has 'score_bring_wild_hi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Bring object!"
      unless $_[0]->isa('FB::Poker::Score::Bring::Wild');
  },
  builder => '_build_score_bring_wild_hi',
);

sub _build_score_bring_wild_hi {
  return FB::Poker::Score::Bring::Wild->new;
}

has 'score_bring_lo' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Bring object!"
      unless $_[0]->isa('FB::Poker::Score::Bring::Low');
  },
  builder => '_build_score_bring_lo',
);

sub _build_score_bring_lo {
  return FB::Poker::Score::Bring::Low->new;
}

has 'score_high' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::High object!"
      unless $_[0]->isa('FB::Poker::Score::High');
  },
  builder => '_build_score_high',
);

sub _build_score_high {
  return FB::Poker::Score::High->new;
}

has 'score_low8' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Low8 object!"
      unless $_[0]->isa('FB::Poker::Score::Low8');
  },
  builder => '_build_score_low8',
);

sub _build_score_low8 {
  return FB::Poker::Score::Low8->new;
}

has 'score_lowa5' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::LowA5 object!"
      unless $_[0]->isa('FB::Poker::Score::LowA5');
  },
  builder => '_build_score_lowa5',
);

sub _build_score_lowa5 {
  return FB::Poker::Score::LowA5->new;
}

has 'score_low27' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Low27 object!"
      unless $_[0]->isa('FB::Poker::Score::Low27');
  },
  builder => '_build_score_low27',
);

sub _build_score_low27 {
  return FB::Poker::Score::Low27->new;
}

has 'score_badugi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Badugi object!"
      unless $_[0]->isa('FB::Poker::Score::Badugi');
  },
  builder => '_build_score_badugi',
);

sub _build_score_badugi {
  return FB::Poker::Score::Badugi->new;
}

has 'score_badugi27' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Badugi27 object!"
      unless $_[0]->isa('FB::Poker::Score::Badugi27');
  },
  builder => '_build_score_badugi27',
);

sub _build_score_badugi27 {
  return FB::Poker::Score::Badugi27->new;
}

has 'score_chinese' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score::Chinese object!"
      unless $_[0]->isa('FB::Poker::Score::Chinese');
  },
  builder => '_build_score_chinese',
);

sub _build_score_chinese {
  return FB::Poker::Score::Chinese->new;
}

has 'eval_omaha_hi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Omaha object!"
      unless $_[0]->isa('FB::Poker::Eval::Omaha');
  },

  #builder => '_build_eval_omaha_hi',
);

sub _build_eval_omaha_hi {
  my $self = shift;
  return FB::Poker::Eval::Omaha->new( scorer => $self->score_high );
}

has 'eval_omaha_low8' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Omaha object!"
      unless $_[0]->isa('FB::Poker::Eval::Omaha');
  },

  #builder => '_build_eval_omaha_low8',
);

sub _build_eval_omaha_low8 {
  my $self = shift;
  return FB::Poker::Eval::Omaha->new( scorer => $self->score_low8 );
}

has 'eval_community_hi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Community object!"
      unless $_[0]->isa('FB::Poker::Eval::Community');
  },

  #builder => '_build_eval_community_hi',
);

sub _build_eval_community_hi {
  my $self = shift;
  return FB::Poker::Eval::Community->new( scorer => $self->score_high );
}

has 'eval_community_low8' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Community object!"
      unless $_[0]->isa('FB::Poker::Eval::Community');
  },

  #builder => '_build_eval_community_low8',
);

sub _build_eval_community_low8 {
  my $self = shift;
  return FB::Poker::Eval::Community->new( scorer => $self->score_low8 );
}

has 'eval_community_low27' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Community object!"
      unless $_[0]->isa('FB::Poker::Eval::Community');
  },

  #builder => '_build_eval_community_low27',
);

sub _build_eval_community_low27 {
  my $self = shift;
  return FB::Poker::Eval::Community->new( scorer => $self->score_low27 );
}

has 'eval_community_lowa5' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Community object!"
      unless $_[0]->isa('FB::Poker::Eval::Community');
  },

  #builder => '_build_eval_community_lowa5',
);

sub _build_eval_community_lowa5 {
  my $self = shift;
  return FB::Poker::Eval::Community->new( scorer => $self->score_lowa5 );
}

has 'eval_wild_hi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Wild object!"
      unless $_[0]->isa('FB::Poker::Eval::Wild');
  },

  #builder => '_build_eval_wild_hi',
);

sub _build_eval_wild_hi {
  my $self = shift;
  return FB::Poker::Eval::Wild->new( scorer => $self->score_high );
}

has 'eval_badugi' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Badugi object!"
      unless $_[0]->isa('FB::Poker::Eval::Badugi');
  },
);

sub _build_eval_badugi {
  my $self = shift;
  return FB::Poker::Eval::Badugi->new( scorer => $self->score_badugi );
}

has 'eval_highsuit' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval object!"
      unless $_[0]->isa('FB::Poker::Eval');
  },
);

sub _build_eval_highsuit {
  my $self = shift;
  return FB::Poker::Eval::HighSuit->new(
    scorer => $self->score_highsuit,
    high_suit => 's',
  );
}

has 'eval_bitch' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval object!"
      unless $_[0]->isa('FB::Poker::Eval');
  },
  builder => '_build_eval_bitch',
);

sub _build_eval_bitch {
  my $self = shift;
  return FB::Poker::Eval::Bitch->new(
    bitch_card => 'Qs',
  );
}


has 'score_highsuit' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Score object!"
      unless $_[0]->isa('FB::Poker::Score::HighSuit');
  },
  builder => '_build_score_highsuit',
);

sub _build_score_highsuit {
  return FB::Poker::Score::HighSuit->new;
}

has 'eval_badugi27' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Badugi27 object!"
      unless $_[0]->isa('FB::Poker::Eval::Badugi27');
  },

  #builder => '_build_eval_badugi27',
);

sub _build_eval_badugi27 {
  my $self = shift;
  return FB::Poker::Eval::Badugi27->new( scorer => $self->score_badugi27 );
}

has 'eval_chinese' => (
  is  => 'rw',
  isa => sub {
    die "Not a FB::Poker::Eval::Chinese object!"
      unless $_[0]->isa('FB::Poker::Eval::Chinese');
  },

  #builder => '_build_eval_chinese',
);

sub _build_eval_chinese {
  my $self = shift;
  return FB::Poker::Eval::Chinese->new(
    chinese_scorer => $self->score_chinese,
    scorer         => $self->score_high
  );
}

sub _make_table {
  my ( $self, $opts ) = @_;
  my $game_opts = $self->game_class->{ $opts->{game_class} };
  $game_opts->{lobby_watch} = $self->lobby_watch;
  return $game_opts if $game_opts;
}

sub ring_table {
  my ( $self, $opts ) = @_;
  my $game_opts = $self->_make_table($opts);
  return unless $game_opts->{camel_class};
  my $class = 'FB::Poker::Table::Ring::' . $game_opts->{camel_class};

  # add channel
  $game_opts->{chat} = FB::Chat->new(
    channel  => 'r' . $opts->{table_id},
    table_id => $opts->{table_id},
  );

  return $class->new( { %$opts, %$game_opts } );
}

sub tour_table {
  my ( $self, $opts ) = @_;
  
  my $game_opts = $self->_make_table($opts);

  return unless $game_opts->{camel_class};
  my $class = 'FB::Poker::Table::Tourney::' . $game_opts->{camel_class};

  $game_opts->{chat} = FB::Chat->new(
    channel  => 't' . $opts->{tour_id} . '-' . $opts->{table_id},
    table_id => $opts->{table_id},
    tour_id  => $opts->{tour_id},
  );
  return $class->new( { %$opts, %$game_opts } );
  #return $class->new( $game_opts );
}

sub BUILD {
  my $self = shift;
  $self->eval_community_hi( $self->_build_eval_community_hi );
  $self->eval_community_low8( $self->_build_eval_community_low8 );
  $self->eval_community_low27( $self->_build_eval_community_low27 );
  $self->eval_community_lowa5( $self->_build_eval_community_lowa5 );
  $self->eval_omaha_hi( $self->_build_eval_omaha_hi );
  $self->eval_omaha_low8( $self->_build_eval_omaha_low8 );
  $self->eval_wild_hi( $self->_build_eval_wild_hi );
  $self->eval_badugi( $self->_build_eval_badugi );
  $self->eval_badugi27( $self->_build_eval_badugi27 );
  $self->eval_chinese( $self->_build_eval_chinese );
  $self->eval_highsuit( $self->_build_eval_highsuit );
  $self->game_class( $self->_build_game_class );
}

1;
