package FB::Poker::Table::TripleDrawHiLo;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::TripleDraw';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
