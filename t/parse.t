use strict;
use warnings;
use Math::Calc::Parser;
use Test::More;

my $parser = Math::Calc::Parser->new;

my $parsed = Math::Calc::Parser->parse('');
is_deeply $parsed, [], 'Parsed empty expression';
$parsed = $parser->parse('1');
is_deeply $parsed, [{type => 'number', value => 1}], 'Parsed lone number';

my $twoplustwo = [{type => 'number', value => 2},
	{type => 'number', value => 2},
	{type => 'operator', value => '+'}];
$parsed = $parser->parse('2+2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2';
$parsed = $parser->parse('2    + 2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with whitespace';
$parsed = $parser->parse('(2)+2');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with parentheses';
$parsed = $parser->parse('(2+2)');
is_deeply $parsed, $twoplustwo, 'Parsed 2+2 with parentheses';
my $twotimestwo = [{type => 'number', value => 2},
	{type => 'number', value => 2},
	{type => 'operator', value => '*'}];
$parsed = $parser->parse('2*2');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2';
$parsed = $parser->parse('(2)2');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2 with implicit multiplication';
$parsed = $parser->parse('2 (2)');
is_deeply $parsed, $twotimestwo, 'Parsed 2*2 with implicit multiplication';

$parsed = $parser->parse('2+3*4');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'number', value => 4},
	{type => 'operator', value => '*'},
	{type => 'operator', value => '+'}], 'Parsed 2+3*4';
$parsed = $parser->parse('(2+3)4');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'operator', value => '+'},
	{type => 'number', value => 4},
	{type => 'operator', value => '*'}], 'Parsed (2+3)*4';
$parsed = $parser->parse('2^3*4/5');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'operator', value => '^'},
	{type => 'number', value => 4},
	{type => 'operator', value => '*'},
	{type => 'number', value => 5},
	{type => 'operator', value => '/'}], 'Parsed 2^3*4/5';
$parsed = $parser->parse('(2^(3*4))/5');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'number', value => 4},
	{type => 'operator', value => '*'},
	{type => 'operator', value => '^'},
	{type => 'number', value => 5},
	{type => 'operator', value => '/'}], 'Parsed (2^(3*4))/5';

$parsed = $parser->parse('2--3');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'operator', value => 'u-'},
	{type => 'operator', value => '-'}], 'Parsed unary minus';
$parsed = $parser->parse('2-+3');
is_deeply $parsed, [{type => 'number', value => 2},
	{type => 'number', value => 3},
	{type => 'operator', value => 'u+'},
	{type => 'operator', value => '-'}], 'Parsed unary plus';

$parsed = $parser->parse('ln(5)');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'function', value => 'ln'}], 'Parsed function';
$parsed = $parser->parse('ln 5');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'function', value => 'ln'}], 'Parsed function';
$parsed = $parser->parse('5 ln 5');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'number', value => 5},
	{type => 'function', value => 'ln'},
	{type => 'operator', value => '*'}], 'Parsed function with implicit multiplication';
$parsed = $parser->parse('ln (5*3)');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'number', value => 3},
	{type => 'operator', value => '*'},
	{type => 'function', value => 'ln'}], 'Parsed function with expression in args';
$parsed = $parser->parse('ln 5*3');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'number', value => 3},
	{type => 'operator', value => '*'},
	{type => 'function', value => 'ln'}], 'Parsed function with bare expression in args';
$parsed = $parser->parse('rand');
is_deeply $parsed, [{type => 'function', value => 'rand'}], 'Parsed no-arg function';
$parsed = $parser->parse('rand 5');
is_deeply $parsed, [{type => 'function', value => 'rand'},
	{type => 'number', value => 5},
	{type => 'operator', value => '*'}], 'Parsed no-arg function with implicit multiplication';
$parsed = $parser->parse('log rand 5');
is_deeply $parsed, [{type => 'function', value => 'rand'},
	{type => 'number', value => 5},
	{type => 'operator', value => '*'},
	{type => 'function', value => 'log'}], 'Parsed no-arg function with implicit multiplication';
$parsed = $parser->parse('log(rand)5');
is_deeply $parsed, [{type => 'function', value => 'rand'},
	{type => 'function', value => 'log'},
	{type => 'number', value => 5},
	{type => 'operator', value => '*'}], 'Parsed no-arg function parenthesized';
$parsed = $parser->parse('logn(ln 5, e 3)');
is_deeply $parsed, [{type => 'number', value => 5},
	{type => 'function', value => 'ln'},
	{type => 'function', value => 'e'},
	{type => 'number', value => '3'},
	{type => 'operator', value => '*'},
	{type => 'function', value => 'logn'}], 'Parsed multi-arg function';

done_testing;
