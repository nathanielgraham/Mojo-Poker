package FB::Poker::Table::Bitch;
use Moo;

extends 'FB::Poker::Table';
with 'FB::Poker::Rules::Bitch';
with 'FB::Poker::Rules::High';
with 'FB::Poker::Rules::Low';

1;
