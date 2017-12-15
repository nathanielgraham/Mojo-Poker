package FB::Poker::Table::FTQ;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::FTQ';
with 'FB::Poker::Rules::High';

1;
