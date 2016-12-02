PCalc
=====

PCalc is a [discrete distribution][1] probability calculator.

[1]: https://en.wikipedia.org/wiki/Probability_distribution#Discrete_probability_distribution

### Example

##### Input

	n = 10
	X ~ Binomial(n, .5)

	? P(X > 3)
	? E(X)

##### Output

|Query|Result|
|--:|:--|
||.828125|
||5|

### Building

To convert the parser to js, run the following:

	$ pegjs -e parser --format globals parser.pegjs
