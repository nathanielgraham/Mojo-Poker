package FB::Poker::Table::Badugi;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Badugi';

1;
