using Cat


@category Smooth

# The only objects in smooth are Nothing, R, and products of these
const R = Float64

# Basic algebra
@arrow Smooth Plus :: (R, R) --> R
@arrow Smooth Mult :: (R, R) --> R
@arrow Smooth Neg :: R --> R
# Calc 1
@arrow Smooth Exp :: R --> R
@arrow Smooth Sin :: R --> R
@arrow Smooth Cos :: R --> R

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
    cos(a)
end
@interpret function (e::Eval)(m::Cos, a)
    sin(a)
end

# Test it out
x = Variable()
y = cos(x + 3.0)
z = sin(y) + cos(x)

println(Eval()(z, 1.0))
