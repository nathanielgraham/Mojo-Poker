package FB::Poker::Table::Holdem;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Holdem';

1;
