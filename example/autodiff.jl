using Cat

# "Real" numbers
const R = Float64

# The only objects in Smooth are Nothing, R, and products of these
@category Smooth where objects = obj -> obj in (Nothing, R, Tuple)
# @category Linear ⊂ Smooth arrows = (Plus, Mult, Neg)

# Basic algebra
@arrow Smooth Plus{T} :: (T, T) --> T
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

@functor Diff :: Smooth --> Smooth begin
    objects = o -> (o, o)
end

@funct function (e::Diff)(m::Plus, (a, da), (b, db))
    a+b, da + db
end

@funct function (e::Diff)(m::Mult, (a, da), (b, db))
    a*b, a*da + b*db
end

@funct function (d::Diff)(m::Smooth.Constant, _)
    m.value, zero()
end

@funct function (d::Diff)(m::Exp, (a, da))
    Exp(a), Mult(da, Exp(a))
end

@funct function (e::Diff)(m::Sin, (a, da))
    Sin(a), da*Cos(a),
end

@funct function (e::Diff)(m::Cos, (a, da))
    Cos(a), -da*Sin(a)
end

# Test it out
x = Variable()
y = cos(x + 3.0)
z = sin(y) + cos(x)

dz = Diff(z)

println(Eval()(z, 1.0))
println(Eval()(dz, (1.0, 1.0)))
