package FB::Poker::Table::Pineapple;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Pineapple';

1;
