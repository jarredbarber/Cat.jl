# 🐱.jl - Cartesian Closed Categories

Library for building composable DSLs with multiple interpretaions ala [Compiling To Categories](http://conal.net/papers/compiling-to-categories)

Example (probabilistic modeling, `examples/microppl.jl`):

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

"Hook for common state update rules; called when @interpret is used"
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
