package FB::Poker::Table::CourchevalHiLo;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::Courcheval';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
