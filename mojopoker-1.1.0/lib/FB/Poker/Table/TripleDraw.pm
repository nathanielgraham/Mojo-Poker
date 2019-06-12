package FB::Poker::Table::TripleDraw;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::TripleDraw';
with 'FB::Poker::Rules::High';

1;
