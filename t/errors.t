use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Test::More;

my $parser = Math::Calc::Parser->new;

my $res = eval { $parser->parse('('); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->parse('e)'); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->parse('log , 2'); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->parse('invalid'); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->evaluate([{type => 'operator', value => '*'}]); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->evaluate([{type => 'unknown', value => 'unknown'}]); 1 };
ok !$res, "Exception: $@";
$res = eval { calc '5/0'; 1 };
ok !$res, "Exception: $@";
my $result = $parser->try_evaluate([{type => 'number', value => 2},
	{type => 'number', value => 3}]);
is $result, undef, "Exception evaluating expression";
ok $parser->error, "Exception is ".$parser->error;
$result = Math::Calc::Parser->try_evaluate('');
is $result, undef, "Exception evaluating expression";
ok $Math::Calc::Parser::ERROR, "Exception is $Math::Calc::Parser::ERROR";

done_testing;
