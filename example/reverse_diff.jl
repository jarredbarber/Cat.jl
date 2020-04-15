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


#=
Reverse mode diff:

In reverse mode AD, we take a function a -> b
and convert it to a function (a, db) -> (b, da)
where "da" is the space of "differentials of a"; 
for our basic setup here, where we work in R^N, da == a,
but this could be something like e.g. a tangent/cotangent bundle.
Basically, the RDiff function takes an input and an output differential
and converts them to an output and an input differential.

Mathematically (from a categorical point of view), RDiff is a functor
that takes the Smooth category to a new category where:
(1) the objects are the same as Smooth
and 
(2) a morphism (arrow) from A ~> B corresponds to an arrow (A x dB) -> (B x dA) in Smooth
so, we have the same objects/morphisms as smooth, but we are basically changing what composition
means: A ~> B  and B ~> C compose to A ~> C, but the composition rules aren't the same
as Smooth.  This is kind of similar to how Kleisli composition works.

We handle this in _code_ by simply re-using Smooth and changing out RDiff acts on composition.
The downside to this (compared to, say, ForwardDiff) is that we lose some of the automagicness
of letting Cat.jl define how the functor acts on all of the built-in arrows (product, terminal, constant, etc...)
=#
@functor RDiff :: Smooth => Smooth (T -> T)

#= RDiff(m::Smooth.Identity{T}) where {T} = Smooth.Identity{RDiff(T)}() =#
# Cartesian
#= RDiff(m::Smooth.Product) = Smooth.Product([RDiff(x) for x in m.factors]...) =#
# A ~> (B, C), e.g., needs to go to (A, (dB, dC)) -> ((B, C), dA)
RDiff(m::Smooth.Product) = begin
    dum = Smooth.Identity{Tuple{source(m), target(m)}}()
    # Each factor maps to an (A, dB) -> (B, dA)
    factors = []
    for k in 1:length(m.factors)
        x = m.factors[k]
        push!(factors, compose(RDiff(x), Smooth.Product(dum[1], dum[2][k])))
    end
    dA = sum([f[2] for f in factors])
    b = Smooth.Product([f[1] for f in factors]...)
    out = Smooth.Product(b, dA)
    out
end

RDiff(m::Smooth.Proj{A, B}) where {A,B} = begin
    @assert false # this is actually not impelmented properly but we don't need it for this example
end

# Terminal is T ~> Nothing, so (T, Nothing) -> (Nothing, T)
RDiff(m::Smooth.Terminal{T}) where {T <: AbstractFloat} = compose(Smooth.Constant( (nothing, 0.0) ),
                                                                  Smooth.Terminal{Tuple{T, Nothing}}())
# Functions compose differently under reverse mode
function RDiff(m::Smooth.Composed)
    # f::a -> b
    # g::b -> c
    inps = Smooth.Identity{Tuple{source(m.f), target(m.g)}}()
    df = RDiff(m.f) # df :: (a, db) -> (b, da)
    dg = RDiff(m.g) # dg :: (b, dc) -> (c, db)
    # We need to "intertwine" these to get:
    # dg o df :: (a, dc) -> (c, da)
    #=
    z = dg(f(inps[1]), inps[2])
    w = df(inps[1], z[2])
    (w[2], z[1])
    =#
    f = compose(m.f, inps[1]) # A better implementation would memoize f
    z = compose(dg, Smooth.Product(f, inps[2])) # z :: (~) ~> (c, db)
    w = compose(df, Smooth.Product(inps[1], z[2]))
    Smooth.Product(z[1], w[2])
end

function split_inputs(m::Smooth.Arrow)
    a = Smooth.Identity{Tuple{source(m), target(m)}}()
    return (a[1], a[2])
end

function RDiff(m::Plus)
    a, db = split_inputs(m)
    Smooth.Product(a[1] + a[2],
                   Smooth.Product(db, db))
end

function RDiff(m::Mult)
    a, db = split_inputs(m)
    Smooth.Product(a[1]*a[2],
                   Smooth.Product(a[1]*db, a[2]*db))
end

function RDiff(m::Smooth.Constant)
    # map inputs into Nothing, then return a constant
    compose(Smooth.Product(Smooth.Constant(m.val),
                           Smooth.Constant(nothing)),
            Smooth.Terminal{Tuple{Nothing, target(m)}}())
end

function RDiff(m::Exp)
    a, db = split_inputs(m)
    u = exp(a)
    Smooth.Product(u, db*u)
end

function RDiff(m::Sin)
    a, db = split_inputs(m)
    Smooth.Product(sin(a), db*cos(a))
end

function RDiff(m::Cos)
    a, db = split_inputs(m)
    Smooth.Product(cos(a), -db*sin(a))
end

# Here is the actual "user code"
x = Placeholder()
y = cos(sin(x))
y = exp(y*y) + 2.0
dy = RDiff(y)

a = 1.0
ya = Eval()(y, a)
ya2 = Eval()(y, a+1e-3)
println("y($a)=$(ya)")
println("dy($a)=$(Eval()(dy, a, 1.0))")
println("Numerical deriv: $(1e3*(ya2-ya))")


