package FB::Poker::Table::OmahaFiveHiLo;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::OmahaFive';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
