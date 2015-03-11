use strict;
use warnings;
use Math::Calc::Parser;
use Math::Complex;
use Test::More;

my $parser = Math::Calc::Parser->new;
$parser->add_functions(my_function => sub { 5 });
is $parser->evaluate('my_function'), 5, 'Added no-arg function';
$parser->add_functions(my_function => { args => 2, code => sub { $_[0]+$_[1]+1 } });
is $parser->evaluate('my_function(2,3)'), 6, 'Added two-arg function';
is $parser->try_evaluate('my_function 2'), undef, 'Exception calling two-arg function with one arg';
$parser->remove_functions('pi');
is $parser->try_evaluate('pi'), undef, 'Removed function "pi"';
$parser->add_functions(text => sub { '45blah' });
is $parser->evaluate('text'), 45, 'Results cast to number';

my $parser2 = Math::Calc::Parser->new;
is $parser2->try_evaluate('my_function(2,3)'), undef, 'Custom function specific to parser object';
is $parser2->try_evaluate('pi'), pi, 'Function removal specific to parser object';

done_testing;
