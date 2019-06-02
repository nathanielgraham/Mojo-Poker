package FB::Poker::Table::StudHiLo;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::Stud';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
