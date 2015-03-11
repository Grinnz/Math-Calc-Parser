use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Math::Complex 'cplx', 'i';
use Test::More;

my $parser = Math::Calc::Parser->new;

my $result = Math::Calc::Parser->evaluate([{type => 'number', value => 2},
	{type => 'number', value => 2},
	{type => 'operator', value => '+'}]);
is $result, 4, 'Evaluated 2+2';
$result = $parser->evaluate([{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'function', value => 'ln'},
	{type => 'operator', value => '*'}]);
is $result, 2*log(3), 'Evaluated 2 ln 3';
$result = $parser->evaluate([{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'number', value => 4},
	{type => 'number', value => 5},
	{type => 'operator', value => '+'},
	{type => 'operator', value => '*'},
	{type => 'operator', value => '^'}]);
cmp_ok $result, '==', cplx(2)**(3*(4+5)), 'Evaluated 2^(3*(4+5))';
$result = $parser->evaluate([{type => 'function', value => 'i'},
	{type => 'function', value => 'i'},
	{type => 'operator', value => '*'}]);
cmp_ok $result, '==', -1, 'Evaluated i*i';
$result = $parser->evaluate([{type => 'number', value => 1},
	{type => 'operator', value => 'u-'},
	{type => 'function', value => 'sqrt'}]);
cmp_ok $result, '==', i, 'Evaluated sqrt -1';
$result = $parser->evaluate('1+2*3^4');
cmp_ok $result, '==', 1+2*cplx(3)**4, 'Evaluated 1+2*3^4 as string expression';
$result = calc 'log 7';
is $result, log(7)/log(10), 'Evaluated log 7 with calc()';

done_testing;
