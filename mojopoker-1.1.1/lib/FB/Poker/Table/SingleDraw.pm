package FB::Poker::Table::SingleDraw;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::SingleDraw';
with 'FB::Poker::Rules::High';

1;
