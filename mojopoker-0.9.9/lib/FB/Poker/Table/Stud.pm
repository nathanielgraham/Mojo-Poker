package FB::Poker::Table::Stud;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Stud';

1;
