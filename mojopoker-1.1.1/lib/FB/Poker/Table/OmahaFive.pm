package FB::Poker::Table::OmahaFive;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::OmahaFive';

1;
