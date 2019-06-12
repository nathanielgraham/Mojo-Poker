package FB::Poker::Table::Omaha;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Omaha';

1;
