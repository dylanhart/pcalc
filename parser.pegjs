/*
 * Discrete Distribution Calculator
 * Dylan Hart
 */
{
    var factorial = function(n) {
        var p = 1;
        while (n > 0)
            p *= n--;
        return p;
    };
    var binom = function(n, k) {
        return factorial(n) / factorial(n - k) / factorial(k);
    };

    var isProb = function(p) {
        return p >= 0 && p <= 1;
    }

    var dists = {};
    dists.bernoulli = function(p) {
        return dists.binomial(1, p);
    };
    dists.binomial = function(n, p) {
        if (!isProb(p)) throw new Error(p + ' is not a valid probability');
        if (!Number.isInteger(n)) throw new Error('number of trials must be an integer');
        if (n <= 0) throw new Error('binomial distribution must have at least one trial');
        return {
            p: function(x) {
                if (!Number.isInteger(x) || x < 0 || x > n)
                    return 0;
                return binom(n, x) * Math.pow(p, x) * Math.pow(1-p, n-x);
            },
            F: function(i) {
                if (!Number.isInteger(i))
                    i = Math.floor(i);
                if (i >= n) return 1;
                if (i < 0) return 0;
                var sum = 0;
                while (i >= 0) {
                    sum += this.p(i--);
                }
                return sum;
            },
            E: function() {
                return n*p;
            },
            toString: function() {
                return "binomial(" + n + ", " + p + ")";
            }
        };
    };
    dists.geometric = function(p) {
        if (!isProb(p)) throw new Error(p + ' is not a valid probability');
        return {
            p: function(x) {
                if (!Number.isInteger(x) || x <= 0)
                    return 0;
                return Math.pow(1-p, x-1) * p
            },
            F: function(i) {
                if (!Number.isInteger(i))
                    i = Math.floor(i);
                if (i < 0) return 0;
                var sum = 0;
                while (i > 0) {
                    sum += this.p(i--);
                }
                return sum;
            },
            E: function() {
                return 1 / p;
            }
        };
    };
    dists.hypergeometric = function(N, m, n) {
        if (!Number.isInteger(N) || !Number.isInteger(n) || !Number.isInteger(m)) throw new Error('HyperGeometic arguments must be integers');
        if (m > N) throw new Error('number marked cannot be larger than total number for HyperGeometric distribution');
        if (n > N) throw new Error('number chosen cannot be larger than total number for HyperGeometric distribution');
        return {
            p: function(x) {
                if (!Number.isInteger(x) || x < 0 || x > m)
                    return 0;
                return binom(m, x) * binom(N-m, n-x) / binom(N, n);
            },
            F: function(i) {
                if (!Number.isInteger(i))
                    i = Math.floor(i);
                if (i >= m) return 1;
                if (i < 0) return 0;
                var sum = 0;
                while (i >= 0) {
                    sum += this.p(i--);
                }
                return sum;
            },
            E: function() {
                return n * N / (m + n);
            }
        };
    };
    dists.poisson = function(l) {
        return {
            p: function(x) {
                if (!Number.isInteger(x) || x < 0)
                    return 0;
                return Math.pow(l, x) / factorial(x) * Math.exp(-l);
            },
            F: function(i) {
                if (!Number.isInteger(i))
                    i = Math.floor(i);
                if (i < 0) return 0;
                var sum = 0;
                while (i >= 0) {
                    sum += this.p(i--);
                }
                return sum;
            },
            E: function() {
                return l;
            }
        };
    };

    var epsilon = .00001;

    var env = {};
    var scalars = {};
}

Stmts
    = _ h:Stmt t:Stmts {
        t.unshift(h);
        return t;
    }
    / _ s:Stmt _ {
        return [s];
    }

Stmt = (RVarStmt / VarStmt / QueryStmt / Comment)

Comment = $('#'[^\n]*)'\n'

RVarStmt = rvar:RVar _ "~" _ dist:DistName _ POpen _ args:Args _ PClose {
    if (dists[dist].length != args.length)
        throw new Error('invalid arg count to ' + dist + ' distribution');
    env[rvar] = dists[dist].apply(this, args);
    return rvar + ' was assigned';
}

VarStmt = v:Var _ '=' _ val:Expr {
    scalars[v] = val;
    return v + ' was assigned';
}

QueryStmt = tag:$([A-Za-z0-9./_ ]+)? '?' _ val:Expr {
    tag = (tag && tag.trim()) || '';
    return [tag, val];
}

Args
    = h:Arg _ ',' _ t:Args {
        t.unshift(h);
        return t;
    }
    / a:Arg {
        return [a];
    }
Arg = Expr

RVar = r:$([A-Z][A-Za-z0-9_]*)
/* ! {
    return (r === 'P' || r === 'E')
}*/
Var = $([a-z][A-Za-z0-9_]*)
Number = n:$([+-]?([0-9]+('.'[0-9]*)?/'.'[0-9]+)([eE][0-9]+)?) {
    return parseFloat(n);
}

Expr = a:Term ops:AddOp* {
    return ops.reduce(function(acc, op) {
        if (op.op === '+')
            return acc + op.val;
        if (op.op === '-')
            return acc - op.val;
    }, a);
}
AddOp = _ op:[+-] _ val:Term {
    return {op: op, val: val};
}

Term = a:Factor ops:MulOp* {
    return ops.reduce(function(acc, op) {
        if (op.op === '*')
            return acc * op.val;
        if (op.op === '/')
            return acc / op.val;
        if (op.op === '%')
            return acc % op.val;
    }, a);
}
MulOp = _ op:[*/%] _ val:Factor {
    return {op: op, val: val};
}

Factor = a:Value ops:ExpOp* {
    return ops.reduce(function(acc, e) {
        return Math.pow(acc, e);
    }, a);
}
ExpOp = _ '^' _ val:Value {
    return val;
}

Value
    = Number / v:Var {
        if (scalars[v] === undefined)
            throw new Error('variable ' + v + ' does not exist');
        return scalars[v];
    }
    / POpen e:Expr PClose {
        return e;
    }
    / 'P' _ POpen _ val:Inequality _ PClose {
        return val;
    }
    / 'E' _ POpen _ rvar:RVar _ PClose {
        if (env[rvar] === undefined)
            throw new Error('random variable ' + rvar + ' does not exist');
        return env[rvar].E();
    }

Inequality
    = rvar:RVar _ op:('='/'!='/'>='/'>'/'<='/'<') _ val:Expr {
        if (env[rvar] === undefined)
            throw new Error('random variable ' + rvar + ' does not exist');
        switch (op) {
        case '=': return env[rvar].p(val);
        case '!=': return 1 - env[rvar].p(val);
        case '<=': return env[rvar].F(val);
        case '<': return env[rvar].F(val-epsilon);
        case '>=': return 1 - env[rvar].F(val-epsilon);
        case '>': return 1 - env[rvar].F(val);
        }
        throw new Error('invalid operator ' + op);
}
    / val:Expr _ op:('='/'!='/'>='/'>'/'<='/'<') _ rvar:RVar {
        if (env[rvar] === undefined)
            throw new Error('random variable ' + rvar + ' does not exist');
        switch (op) {
        case '=': return env[rvar].p(val);
        case '!=': return 1 - env[rvar].p(val);
        case '>=': return env[rvar].F(val);
        case '>': return env[rvar].F(val-epsilon);
        case '<=': return 1 - env[rvar].F(val-epsilon);
        case '<': return 1 - env[rvar].F(val);
        }
        throw new Error('invalid operator ' + op);
}

// whitespace
_ = [\t\n ]* {return null;}

DistName = n:("bernoulli"i/"binomial"i/"geometric"i/"hypergeometric"i/"poisson"i) {
    return n.toLowerCase();
}
POpen = "("
PClose = ")"
