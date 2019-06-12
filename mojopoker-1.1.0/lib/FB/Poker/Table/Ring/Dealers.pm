package FB::Poker::Table::Ring::Dealers;
use Moo;

#extends 'FB::Poker::Table';
extends 'FB::Poker::Table::Dealers';
#with 'FB::Poker::Rules::Dealers', 'FB::Poker::Table::Interface::Ring';
with 'FB::Poker::Table::Interface::Ring';
#with 'FB::Poker::Table::Interface';

1;
