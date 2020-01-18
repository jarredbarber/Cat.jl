using Cat
using Random

@category Model

@arrow Model Normal :: (Float64, Float64) --> Float64
@arrow Model Uniform :: Nothing --> Float64

# A functor Model => Set that composes as a state monad
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


z = Normal(1.0, Uniform())
y = Normal(z, 2.0)
x = Normal(z, y)

samples = Sample(5000)(x, nothing)

μ = sum(samples)/length(samples)
σ = sqrt( sum( (samples .- μ).^2 ) / length(samples) )

println("Sample μ/σ: $μ, $σ")

@interpretation Filter (<=) Model begin
    rng::AbstractRNG
    N::Int64
end

@interpret function (s::Sample)(m::Normal, z)

end
