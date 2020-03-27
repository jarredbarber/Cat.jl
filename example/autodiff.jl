using Cat

# "Real" numbers
const R = Float64

# The only objects in Smooth are Nothing, R, and products of these
@category Smooth #where objects = obj -> obj in (Nothing, R, Tuple)

# Basic algebra
@arrow Smooth Plus :: (R, R) --> R
@arrow Smooth Mult :: (R, R) --> R
@arrow Smooth Neg :: R --> R
# Calc 1
@arrow Smooth Exp :: R --> R
@arrow Smooth Sin :: R --> R
@arrow Smooth Cos :: R --> R

# Just an unbound input is equivalent to the identity morphism
Placeholder = Smooth.Identity{R}

@alias Smooth Plus Base.:+ 2
@alias Smooth Neg Base.:- 1
@alias Smooth Mult Base.:* 2 

Base.exp(a::Smooth.Arrow) = Exp(a)
Base.sin(a::Smooth.Arrow) = Sin(a)
Base.cos(a::Smooth.Arrow) = Cos(a)

# Evaluate an expression tree
@interpretation Eval (=>) Smooth

@interpret function (e::Eval)(m::Plus, a, b)
    a + b
end

@interpret function (e::Eval)(m::Mult, a, b)
    a * b
end

@interpret function (e::Eval)(m::Neg, a)
    -a
end

@interpret function (e::Eval)(m::Exp, a)
    exp(a)
end

@interpret function (e::Eval)(m::Sin, a)
    sin(a)
end

@interpret function (e::Eval)(m::Cos, a)
    cos(a)
end

# Functor is a map from arrow -> arrow
# @functor defines a function Diff for all of the
# primitive arrows
@functor Diff :: Smooth => Smooth (T -> Tuple{T, T})

function split_inputs(m::Smooth.Arrow)
    A = Diff(source(m))
    p = A.parameters
    tuple([Smooth.Proj{A, p[k]}(k) for k in 1:length(p)]...)
end

function Diff(m::Plus)
    a, b = split_inputs(m)
    Smooth.Product(a[1] + b[1],
            a[2] + b[2])
end

function Diff(m::Mult)
    a, b = split_inputs(m)
    Smooth.Product(a[1]*b[1],
            a[1]*b[2] + a[2]*b[1])
end

function Diff(m::Smooth.Constant)
    Smooth.Product(Smooth.Constant(m.val),
        Smooth.Constant(0.0))
end

function Diff(m::Exp)
    a, da = split_inputs(m)
    Smooth.Product(exp(a), da*exp(a))
end

function Diff(m::Sin)
    a, da = split_inputs(m)
    Smooth.Product(sin(a), da*cos(a))
end

function Diff(m::Cos)
    a, da = split_inputs(m)
    Smooth.Product(cos(a), -da*sin(a))
end

# Here is the actual "user code"
x = Placeholder()
y = sin(x) + 0.5*cos(x)
y = exp(y*y) + 2.0
dy = Diff(y)

println(Eval()(y, 0.0))
println(Eval()(dy, 0.0, 1.0))
