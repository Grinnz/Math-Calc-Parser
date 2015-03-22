package Math::Calc::Parser;
use strict;
use warnings;
use Carp 'croak';
use Math::Complex;
use POSIX qw/ceil floor/;
use Scalar::Util qw/blessed looks_like_number/;
require Exporter;

our $VERSION = '0.013';
our @ISA = 'Exporter';
our @EXPORT_OK = 'calc';
our $ERROR;

# See disclaimer in Math::Round
use constant ROUND_HALF => 0.50000000000008;

{
	my %operators = (
		'<<' => { assoc => 'left' },
		'>>' => { assoc => 'left' },
		'+'  => { assoc => 'left' },
		'-'  => { assoc => 'left' },
		'*'  => { assoc => 'left' },
		'/'  => { assoc => 'left' },
		'%'  => { assoc => 'left' },
		'^'  => { assoc => 'right' },
		# Dummy operators for unary minus/plus
		'u-' => { assoc => 'right' },
		'u+' => { assoc => 'right' },
	);
	
	# Ordered lowest precedence to highest
	my @op_precedence = (
		['<<','>>'],
		['+','-'],
		['*','/','%'],
		['u-','u+'],
		['^'],
	);
	
	# Cache operator precedence
	my (%lower_prec, %higher_prec);
	$higher_prec{$_} = 1 for keys %operators;
	foreach my $set (@op_precedence) {
		delete $higher_prec{$_} for @$set;
		foreach my $op (@$set) {
			$operators{$op}{equal_to}{$_} = 1 for @$set;
			$operators{$op}{lower_than}{$_} = 1 for keys %higher_prec;
			$operators{$op}{higher_than}{$_} = 1 for keys %lower_prec;
		}
		$lower_prec{$_} = 1 for @$set;
	}
	
	sub _operator {
		my $oper = shift;
		croak 'No operator passed' unless defined $oper;
		return undef unless exists $operators{$oper};
		return $operators{$oper};
	}
	
	sub _real { blessed $_[0] ? $_[0]->Re : $_[0] }
	
	my %functions = (
		'<<'  => { args => 2, code => sub { _real($_[0]) << _real($_[1]) } },
		'>>'  => { args => 2, code => sub { _real($_[0]) >> _real($_[1]) } },
		'+'   => { args => 2, code => sub { $_[0] + $_[1] } },
		'-'   => { args => 2, code => sub { $_[0] - $_[1] } },
		'*'   => { args => 2, code => sub { $_[0] * $_[1] } },
		'/'   => { args => 2, code => sub { $_[0] / $_[1] } },
		'%'   => { args => 2, code => sub { _real($_[0]) % _real($_[1]) } },
		'^'   => { args => 2, code => sub { $_[0] ** $_[1] } },
		'u-'  => { args => 1, code => sub { -$_[0] } },
		'u+'  => { args => 1, code => sub { +$_[0] } },
		sqrt  => { args => 1, code => sub { sqrt $_[0] } },
		pi    => { args => 0, code => sub { pi } },
		i     => { args => 0, code => sub { i } },
		e     => { args => 0, code => sub { exp 1 } },
		ln    => { args => 1, code => sub { log $_[0] } },
		log   => { args => 1, code => sub { log($_[0])/log(10) } },
		logn  => { args => 2, code => sub { log($_[0])/log($_[1]) } },
		sin   => { args => 1, code => sub { sin $_[0] } },
		cos   => { args => 1, code => sub { cos $_[0] } },
		tan   => { args => 1, code => sub { tan $_[0] } },
		asin  => { args => 1, code => sub { asin $_[0] } },
		acos  => { args => 1, code => sub { acos $_[0] } },
		atan  => { args => 1, code => sub { atan $_[0] } },
		abs   => { args => 1, code => sub { abs $_[0] } },
		int   => { args => 1, code => sub { int _real($_[0]) } },
		floor => { args => 1, code => sub { floor _real($_[0]) } },
		ceil  => { args => 1, code => sub { ceil _real($_[0]) } },
		rand  => { args => 0, code => sub { rand } },
		# Adapted from Math::Round
		round => { args => 1, code => sub { _real($_[0]) >= 0
		                                    ? floor(_real($_[0]) + ROUND_HALF)
		                                    : ceil(_real($_[0]) - ROUND_HALF) } },
	);
	
	sub _default_functions { +{%functions} }
	
	my $singleton;
	sub _instance {
		return $_[0] if blessed $_[0];
		$singleton = $_[0]->new unless defined $singleton;
		return $singleton;
	}
}

sub new {
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}

sub _functions {
	my $self = shift;
	$self->{_functions} = _default_functions() unless defined $self->{_functions};
	return $self->{_functions};
}

sub error {
	my $self = _instance(shift);
	return exists $self->{error} ? $self->{error} : undef;
}

sub _set_error {
	my ($self, $error) = @_;
	$self->{error} = $error;
	return $self;
}

sub clear_error {
	my $self = shift;
	delete $self->{error};
}

sub add_functions {
	my ($self, %functions) = @_;
	foreach my $name (keys %functions) {
		croak "Function \"$name\" has invalid name" unless $name =~ m/\A[a-z]\w*\z/i;
		my $definition = $functions{$name};
		$definition = { args => 0, code => $definition } if ref $definition eq 'CODE';
		croak "No argument count for function \"$name\""
			unless defined (my $args = $definition->{args});
		croak "Invalid argument count for function \"$name\""
			unless $args =~ m/\A\d+\z/ and $args >= 0;
		croak "No coderef for function \"$name\""
			unless defined (my $code = $definition->{code});
		croak "Invalid coderef for function \"$name\"" unless ref $code eq 'CODE';
		$self->_functions->{$name} = { args => $args, code => $code };
	}
	return $self;
}

sub remove_functions {
	my ($self, @functions) = @_;
	foreach my $name (grep { defined } @functions) {
		next unless exists $self->_functions->{$name};
		next if defined _operator($name); # Do not remove operator functions
		delete $self->_functions->{$name};
	}
	return $self;
}

my $token_re = qr{(
	( 0x[0-9a-f]+ | 0b[01]+ | 0[0-7]+ ) # Octal/hex/binary numbers
	| (?: \d*\. )? \d+ (?: e[-+]?\d+ )? # Decimal numbers
	| [(),]                             # Parentheses and commas
	| \w+                               # Functions
	| (?: [-+*/^%] | << | >> )          # Operators
)}ix;

sub parse {
	my ($self, $expr) = @_;
	$self = _instance($self);
	my (@expr_queue, @oper_stack, $binop_possible);
	while ($expr =~ /$token_re/g) {
		my ($token, $octal) = ($1, $2);
		
		# Octal/hex/binary numbers
		$token = oct $octal if defined $octal and length $octal;
		
		# Implicit multiplication
		if ($binop_possible and $token ne ')' and $token ne ','
		    and !defined _operator($token)) {
			_shunt_operator(\@expr_queue, \@oper_stack, '*');
		}
		
		if (defined _operator($token)) {
			# Detect unary minus/plus
			if (!$binop_possible and ($token eq '-' or $token eq '+')) {
				$token = "u$token";
			}
			_shunt_operator(\@expr_queue, \@oper_stack, $token);
			$binop_possible = 0;
		} elsif ($token eq '(') {
			_shunt_left_paren(\@expr_queue, \@oper_stack);
			$binop_possible = 0;
		} elsif ($token eq ')') {
			_shunt_right_paren(\@expr_queue, \@oper_stack)
				or die "Mismatched parentheses\n";
			$binop_possible = 1;
		} elsif ($token eq ',') {
			_shunt_comma(\@expr_queue, \@oper_stack)
				or die "Misplaced comma or mismatched parentheses\n";
			$binop_possible = 0;
		} elsif (looks_like_number $token) {
			_shunt_number(\@expr_queue, \@oper_stack, $token);
			$binop_possible = 1;
		} elsif ($token =~ m/\A\w+\z/) {
			die "Invalid function \"$token\"\n" unless exists $self->_functions->{$token};
			if ($self->_functions->{$token}{args} > 0) {
				_shunt_function_with_args(\@expr_queue, \@oper_stack, $token);
				$binop_possible = 0;
			} else {
				_shunt_function_no_args(\@expr_queue, \@oper_stack, $token);
				$binop_possible = 1;
			}
		} else {
			die "Unknown token \"$token\"\n";
		}
	}
	
	# Leftover operators go at the end
	while (@oper_stack) {
		die "Mismatched parentheses\n" if $oper_stack[-1] eq '(';
		push @expr_queue, pop @oper_stack;
	}
	
	return \@expr_queue;
}

sub _shunt_number {
	my ($expr_queue, $oper_stack, $num) = @_;
	push @$expr_queue, $num;
	return 1;
}

sub _shunt_operator {
	my ($expr_queue, $oper_stack, $oper) = @_;
	my $oper_stat = _operator($oper);
	my $assoc = $oper_stat->{assoc};
	while (@$oper_stack and defined _operator(my $top_oper = $oper_stack->[-1])) {
		if ($oper_stat->{lower_than}{$top_oper}
		    or ($assoc eq 'left' and $oper_stat->{equal_to}{$top_oper})) {
			push @$expr_queue, pop @$oper_stack;
		} else {
			last;
		}
	}
	push @$oper_stack, $oper;
	return 1;
}

sub _shunt_function_with_args {
	my ($expr_queue, $oper_stack, $function) = @_;
	push @$oper_stack, $function;
	return 1;
}

sub _shunt_function_no_args {
	my ($expr_queue, $oper_stack, $function) = @_;
	push @$expr_queue, $function;
	return 1;
}

sub _shunt_left_paren {
	my ($expr_queue, $oper_stack) = @_;
	push @$oper_stack, '(';
	return 1;
}

sub _shunt_right_paren {
	my ($expr_queue, $oper_stack) = @_;
	while (@$oper_stack and $oper_stack->[-1] ne '(') {
		push @$expr_queue, pop @$oper_stack;
	}
	return 0 unless @$oper_stack and $oper_stack->[-1] eq '(';
	pop @$oper_stack;
	if (@$oper_stack and $oper_stack->[-1] ne '('
	    and !defined _operator($oper_stack->[-1])) {
		# Not parentheses or operator, must be function
		push @$expr_queue, pop @$oper_stack;
	}
	return 1;
}

sub _shunt_comma {
	my ($expr_queue, $oper_stack) = @_;
	while (@$oper_stack and $oper_stack->[-1] ne '(') {
		push @$expr_queue, pop @$oper_stack;
	}
	return 0 unless @$oper_stack and $oper_stack->[-1] eq '(';
	return 1;
}

sub calc ($) { __PACKAGE__->evaluate($_[0]) }

sub evaluate {
	my ($self, $expr) = @_;
	$self = _instance($self);
	$expr = $self->parse($expr) unless ref $expr eq 'ARRAY';
	
	die "No expression to evaluate\n" unless @$expr;
	
	my @eval_stack;
	foreach my $token (@$expr) {
		die "Undefined token in evaluate\n" unless defined $token;
		if (exists $self->_functions->{$token}) {
			my $function = $self->_functions->{$token};
			my $num_args = $function->{args};
			die "Malformed expression\n" if @eval_stack < $num_args;
			my @args = $num_args > 0 ? splice @eval_stack, -$num_args : ();
			local $@;
			my $result;
			my $rc = eval { $result = $function->{code}(@args); 1 };
			unless ($rc) {
				my $err = $@;
				$err =~ s/ at .+? line \d+\.$//i;
				die $err;
			}
			die "Undefined result from function or operator \"$token\"\n" unless defined $result;
			{
				no warnings 'numeric';
				push @eval_stack, 0+$result;
			}
		} elsif (looks_like_number $token) {
			push @eval_stack, $token;
		} else {
			die "Invalid function or operator \"$token\"\n";
		}
	}
	
	die "Malformed expression\n" if @eval_stack > 1;
	
	return $eval_stack[0];
}

sub try_evaluate {
	my ($self, $expr) = @_;
	$self = _instance($self);
	$self->clear_error;
	undef $ERROR;
	local $@;
	my $result;
	my $rc = eval { $result = $self->evaluate($expr); 1 };
	unless ($rc) {
		my $err = $@;
		chomp $err;
		$self->_set_error($ERROR = $err);
		return undef;
	}
	return $result;
}

=encoding utf8

=head1 NAME

Math::Calc::Parser - Parse and evaluate mathematical expressions

=head1 SYNOPSIS

  use Math::Calc::Parser 'calc';
  
  my $result = calc '2 + 2'; # 4
  my $result = calc 'int rand 5'; # Random integer between 0 and 4
  my $result = calc 'sqrt -1'; # i
  my $result = calc '0xff << 2'; # 1020
  my $result = calc '1/0'; # Division by 0 exception
  
  # Class methods
  my $result = Math::Calc::Parser->evaluate('2 + 2'); # 4
  my $result = Math::Calc::Parser->evaluate('3pi^2'); # 29.608813203268
  my $result = Math::Calc::Parser->evaluate('0.7(ln 4)'); # 0.970406052783923
  
  # With more advanced error handling
  my $result = Math::Calc::Parser->try_evaluate('rand(abs'); # undef (Mismatched parentheses)
  if (defined $result) {
    print "Result: $result\n";
  } else {
    print "Error: ".Math::Calc::Parser->error."\n";
  }
  
  # Or as an object for more control
  my $parser = Math::Calc::Parser->new;
  $parser->add_functions(triple => { args => 1, code => sub { $_[0]*3 } });
  $parser->add_functions(pow => { args => 2, code => sub { $_[0] ** $_[1] });
  $parser->add_functions(one => sub { 1 }, two => sub { 2 }, three => sub { 3 });
  
  my $result = $parser->evaluate('2(triple one)'); # 2*(1*3) = 6
  my $result = $parser->evaluate('pow(triple two, three)'); # (2*3)^3 = 216
  my $result = $parser->try_evaluate('triple triple'); # undef (Malformed expression)
  die $parser->error unless defined $result;
  
  $parser->remove_functions('pi', 'e');
  $parser->evaluate('3pi'); # Invalid function exception

=head1 DESCRIPTION

L<Math::Calc::Parser> is a simplified mathematical expression evaluator with
support for complex and trigonometric operations, implicit multiplication, and
perlish "parentheses optional" functions, while being safe for arbitrary user
input. It parses input strings into a structure based on
L<Reverse Polish notation|http://en.wikipedia.org/wiki/Reverse_Polish_notation>
(RPN), and then evaluates the result. The list of recognized functions may be
customized using L</"add_functions"> and L</"remove_functions">.

=head1 FUNCTIONS

=head2 calc

  use Math::Calc::Parser 'calc';
  my $result = calc '2+2';
  
  $ perl -MMath::Calc::Parser=calc -E 'say calc "2+2"'

Compact exportable function wrapping L</"evaluate"> for string expressions.
Throws an exception on error.

=head1 ATTRIBUTES

=head2 error

  my $result = $parser->try_evaluate('2//');
  die $parser->error unless defined $result;

Returns the error message after a failed L</"try_evaluate">.

=head1 METHODS

=head2 parse

  my $parsed = Math::Calc::Parser->parse('5 / e^(i*pi)');

Parses a mathematical expression. Can be called as either an object or class
method. On success, returns an array reference representation of the expression
in RPN notation which can be passed to L</"evaluate">. Throws an exception on
failure.

=head2 evaluate

  my $result = Math::Calc::Parser->evaluate($parsed);
  my $result = Math::Calc::Parser->evaluate('log rand 7');

Evaluates a mathematical expression. Can be called as either an object or class
method, and the argument can be either an arrayref from L</"parse"> or a string
expression. Returns the result of the expression on success or throws an
exception on failure.

=head2 try_evaluate

  if (defined (my $result = Math::Calc::Parser->evaluate('floor 2.5'))) {
    print "Result: $result\n";
  } else {
    print "Error: ".Math::Calc::Parser->error."\n";
  }
  
  if (defined (my $result = $parser->evaluate('log(5'))) {
  	print "Result: $result\n";
  } else {
  	print "Error: ".$parser->error."\n";
  }

Same as L</"evaluate"> but instead of throwing an exception on failure, returns
undef and sets the L</"error"> attribute to the error message. The error
message for the most recent L</"try_evaluate"> call can also be retrieved from
the global variable C<$Math::Calc::Parser::ERROR>.

=head2 add_functions

  $parser->add_functions(
    my_function => { args => 5, code => sub { return grep { $_ > 0 } @_; } },
    other_function => sub { 20 }
  );

Adds functions to be recognized by the parser object. Keys are function names
which must start with an alphabetic character and consist only of
L<word characters|http://perldoc.perl.org/perlrecharclass.html#Word-characters>.
Values are either a hashref containing C<args> and C<code> keys, or a coderef
that is assumed to be a 0-argument function. C<args> must be an integer greater
than or equal to C<0>. C<code> or the passed coderef will be called with the
numeric operands passed as parameters, and must either return a numeric result
or throw an exception. Non-numeric results will be cast to numbers in the usual
perl fashion, and undefined results will throw an evaluation error.

=head2 remove_functions

  $parser->remove_functions('rand','nonexistent');

Removes functions from the parser object if they exist. Can be used to remove
default functions as well as functions previously added with
L</"add_functions">.

=head1 OPERATORS

L<Math::Calc::Parser> recognizes the following operators with their usual
definitions.

  +, -, *, /, %, ^, <<, >>

Note: C<+> and C<-> can represent a unary operation (negation) in addition to
addition and subtraction.

=head1 DEFAULT FUNCTIONS

L<Math::Calc::Parser> parses several functions by default, which can be
customized using L</"add_functions"> or L</"remove_functions"> on an object
instance.

=over

=item abs

Absolute value.

=item acos

=item asin

=item atan

Inverse sine, cosine, and tangent.

=item ceil

Round up to nearest integer.

=item cos

Cosine.

=item e

Euler's number.

=item floor

Round down to nearest integer.

=item i

Imaginary unit.

=item int

Cast (truncate) to integer.

=item ln

Natural log.

=item log

Log base 10.

=item logn

Log with arbitrary base given as second argument.

=item pi

π

=item rand

Random value between 0 and 1 (exclusive of 1).

=item round

Round to nearest integer, with halfway cases rounded away from zero.

=item sin

Sine.

=item sqrt

Square root.

=item tan

Tangent.

=back

=head1 CAVEATS

While parentheses are optional for functions with 0 or 1 argument, they are
required when a comma is used to separate multiple arguments.

Due to the nature of handling complex numbers, the evaluated result may be a
L<Math::Complex> object. These objects can be directly printed or used in
numeric operations but may be more difficult to use in comparisons.

Operators and functions that are not defined to operate on complex numbers will
return the result of the operation on the real components of their operands.
This includes the operators C<E<lt>E<lt>>, C<E<gt>E<gt>>, and C<%>, and the
functions C<int>, C<floor>, C<ceil>, and C<round>.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book, C<dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2015, Dan Book.

This library is free software; you may redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Math::Complex>

=cut

1;
