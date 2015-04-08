use strict;
use warnings;
use Test::More;

my $buffer = '';
{
	open my $handle, '>', \$buffer;
	local *STDOUT = $handle;
	use ath;
	2+2
	no ath;
	use ath;
	round e^(i pi)
	no ath;
	use ath;
	5!
	no ath;
}

my @lines = split /\n/, $buffer;
is $lines[0], 4, 'Evaluated 2+2';
is $lines[1], -1, 'Evaluated round e^(i pi)';
is $lines[2], 120, 'Evaluated 5!';

done_testing;
