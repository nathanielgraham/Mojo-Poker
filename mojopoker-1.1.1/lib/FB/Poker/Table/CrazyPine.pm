package FB::Poker::Table::CrazyPine;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::CrazyPine';

1;
