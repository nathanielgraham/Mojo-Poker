package FB::Poker::Table::OmahaHiLo;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::Omaha';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
