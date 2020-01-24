using Cat

# "Real" numbers
const R = Float64

# The only objects in Smooth are Nothing, R, and products of these
@category Smooth #where objects = obj -> obj in (Nothing, R, Tuple)
# @category Linear ⊂ Smooth arrows = (Plus, Mult, Neg)

# Basic algebra
@arrow Smooth Plus :: (R, R) --> R
@arrow Smooth Mult :: (R, R) --> R
@arrow Smooth Neg :: R --> R
# Calc 1
@arrow Smooth Exp :: R --> R
@arrow Smooth Sin :: R --> R
@arrow Smooth Cos :: R --> R

# Just an unbound input is equivalent to the identity morphism
Variable = Smooth.Identity{R}

Base.:+(a::Smooth.Arrow, b) = Plus(a, b)
Base.:+(a, b::Smooth.Arrow) = Plus(a, b)
Base.:+(a::Smooth.Arrow, b::Smooth.Arrow) = Plus(a, b)

Base.:-(a::Smooth.Arrow) = Neg(a)

Base.:*(a::Smooth.Arrow, b) = Mult(a, b)
Base.:*(a, b::Smooth.Arrow) = Mult(a, b)
Base.:*(a::Smooth.Arrow, b::Smooth.Arrow) = Mult(a, b)

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
@functor Diff :: Smooth => Smooth (o -> (o, o))

# this is ugly and needs fixed
# Represents inputs that look like (a, da)
const R2 = Tuple{R,R}
diff_inputs() = (Smooth.Proj{R2,R}(1),
                 Smooth.Proj{R2,R}(2))

diff_inputs2() = begin
    Inp = Tuple{R2, R2}
    (Smooth.Proj{Inp, R2}(1),
     Smooth.Proj{Inp, R2}(2))
end

function Diff(m::Plus)
    a, b = diff_inputs2()
    Smooth.Product(a[1] + b[1],
            a[2] + b[2])
end

function Diff(m::Mult)
    a, b = diff_inputs2()
    Smooth.Product(a[1]*b[1],
            a[1]*b[2] + a[2]*b[1])
end

function Diff(m::Smooth.Constant)
    Smooth.Product(Smooth.Constant(m.val),
        Smooth.Constant(0.0))
end

function Diff(m::Exp)
    a, da = diff_inputs()
    Smooth.Product(exp(a), da*exp(a))
end

function Diff(m::Sin)
    a, da = diff_inputs()
    Smooth.Product(sin(a), da*cos(a))
end

function Diff(m::Cos)
    a, da = diff_inputs()
    Smooth.Product(cos(a), -da*sin(a))
end

# Test it out
x = Variable()
y = sin(x) + cos(x)
# y = exp(y*y)
dy = Diff(y)

println(Eval()(y, 0.0))
println(Eval()(dy, 0.0, 1.0))
