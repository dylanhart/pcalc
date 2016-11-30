PCalc Grammar:
==============

**TODO:**
 - split terms by order of operations
 - fix P to take inequality
 - add E

### Example

	X ~ Binomial(10, .5)
	Y = 2*X + 4

	? P(Y > 3)
	? E(Y)

### Grammar

	<rvar> : [A-Z][a-zA-Z0-9_]*
	<var> : [a-z][a-zA-Z0-9_]*
	<dist> : "Bernoulli" | "Binomial" | ...

	<stmts> : <stmt> | <stmts> <stmt>
	<stmt> : <rvarstmt> | <conststmt> | <querystmt> | <comment>

	<comment> : #[^\n]*\n

	<rvarstmt> : <rvar> ~ <dist> ( <args> ) '\n' | <rvar> = <rvarexpr> '\n'
	<args> : <expr> | <args> , <expr>

	<conststmt> : <var> = <expr> '\n'

	<prob> : P ( <rvarexpr> ) | P ( <rvarexpr> '|' <rvarexpr> )
	<expr> : <value> | <expr> <op> <value>
	<value> : <prob> | <number> | ( <expr> ) | <var>
	<op> : [-+/*^]
	<number> : [+-]?(\d+(\.\d*)?|\.\d+)([eE]\d+)?

	<rvarexpr> : <rvarvalue>
	           | <rvarexpr> <op> <rvarvalue>
	           | <rvarexpr> <op> <value>
	           | <expr> <op> <rvarvalue>
	<rvarvalue> : <rvar>

	<querystmt> : <queryname> ? <expr>
	<queryname> : [\w ]*

	<program> : <stmts>
