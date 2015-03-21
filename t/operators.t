use strict;
use warnings;
use Math::Calc::Parser 'calc';
use Test::More;

is calc '3+2', 5, 'Addition';
is calc '3-2', 1, 'Subtraction';
is calc '3*2', 6, 'Multiplication';
is calc 'int 3/2', 1, 'Division';
is calc '3%2', 1, 'Modulo';
is calc '3^2', 9, 'Exponent';
is calc '3<<2', 12, 'Left shift';
is calc '3>>1', 1, 'Right shift';

done_testing;
