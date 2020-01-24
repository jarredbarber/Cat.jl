# 🐱.jl - Cartesian Closed Categories

Library for building composable DSLs with multiple interpretaions ala [Compiling To Categories](http://conal.net/papers/compiling-to-categories)

## Basic concepts

1. `@category` defines a new category, which is a collection of arrows - composable building blocks.
2. `@arrow` defines a new composable arrow with source/target types
3. `@interpretation` defines an execution of an arrow, which automatically composes.
4. `@functor A => B` defines a mapping between composable arrows of two categories

## Toy examples

Example (forward-mode autodiff, `example/autodiff.jl`):

``` julia
using Cat

# "Real" numbers
const R = Float64

@category Smooth

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
```

Example (probabilistic modeling, `example/microppl.jl`):

```julia
using Cat
using Random

# New category of probabilistic models
@category Model

# Model types are arrows in the category; the types dictate how they compose
@arrow Model Normal :: (Float64, Float64) --> Float64
@arrow Model Uniform :: Nothing --> Float64

"Builds a simple heirarchical model"
function build_model()
    z = Normal(1.0, Uniform())
    y = Normal(z, 2.0)
    x = Normal(z, y)
    x # x is a Model arrow from Nothing --> Float64
end

# An interpretation (aka "representable functor") is specified
# with @interpretation and can optionally include internal state
# definitions
@interpretation Sample (=>) Model begin
    rng::AbstractRNG
    N::Int64
    samples::Dict{Model.Arrow, Any}
    Sample(N) = new(Random.GLOBAL_RNG, N, Dict())
end

# Hook for common state update rules; called when @interpret is used.
# In this case, we need to memoize samples to achieve correct semantics.
function interp_state_hook(s::Sample, m::Model.Arrow, value_expr)
  if !haskey(s.samples, m)
      s.samples[m] = value_expr()
  end
  s.samples[m]
end

"Sample from a normal"
@interpret function (s::Sample)(m::Normal, μ, σ)
    μ .+ σ.*randn(s.rng, s.N)
end

"Sample from a uniform"
@interpret function (s::Sample)(m::Uniform, _)
    rand(s.rng, s.N)
end

test_model = build_model()

samples = Sample(5000)(test_model, nothing)

# summarize the samples
μ = sum(samples)/length(samples)
σ = sqrt( sum( (samples .- μ).^2 ) / length(samples) )

println("Sample stats [μ/σ]: $μ, $σ")
```
