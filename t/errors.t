use strict;
use warnings;
use Math::Calc::Parser;
use Test::More;

my $parser = Math::Calc::Parser->new;

eval { $parser->parse('(') };
ok $@, "Exception: $@";
eval { $parser->parse('e)') };
ok $@, "Exception: $@";
eval { $parser->parse('log , 2') };
ok $@, "Exception: $@";
eval { $parser->parse('invalid') };
ok $@, "Exception: $@";
eval { $parser->evaluate([{type => 'operator', value => '*'}]) };
ok $@, "Exception: $@";
eval { $parser->evaluate([{type => 'unknown', value => 'unknown'}]) };
ok $@, "Exception: $@";
my $result = $parser->try_evaluate([{type => 'number', value => 2},
	{type => 'number', value => 3}]);
is $result, undef, "Exception evaluating expression";
ok $parser->error, "Exception is ".$parser->error;

done_testing;
