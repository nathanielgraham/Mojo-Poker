package FB::Poker::Table::Courcheval;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Courcheval';

1;
