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
$res = eval { $parser->parse('!'); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->evaluate(['*']); 1 };
ok !$res, "Exception: $@";
$res = eval { $parser->evaluate(['unknown']); 1 };
ok !$res, "Exception: $@";
$res = eval { calc '5/0'; 1 };
ok !$res, "Exception: $@";
$parser->add_functions(undef => sub { undef });
$res = eval { $parser->evaluate('undef') };
ok !$res, "Exception: $@";
my $result = $parser->try_evaluate([2,3]);
is $result, undef, "Exception evaluating expression";
ok $parser->error, "Exception is ".$parser->error;
$result = Math::Calc::Parser->try_evaluate('');
is $result, undef, "Exception evaluating expression";
ok $Math::Calc::Parser::ERROR, "Exception is $Math::Calc::Parser::ERROR";
ok +Math::Calc::Parser->error, "Exception is ".Math::Calc::Parser->error;

done_testing;
