using Cat
using Random
using MacroTools

@category Model

@morphism Model Normal {} {Tuple{Float64, Float64}, Float64}

@stateful Sample (=>) Model begin
    rng::AbstractRNG
    N::Int64
    samples::Dict{Model.Arrow, Any}
    Sample(N) = new(Random.GLOBAL_RNG, N, Dict())
end

macro defsampler(state, arrow, args, expr)
    @capture(arrow, m_::T_)
    if args.head == :tuple
        args = args.args
    end

    esc(quote
        function ($state::Sample)($arrow, $(args...))
          if !haskey($state.samples, $m)
            $state.samples[$m] = $expr
          end
          $state.samples[$m]
        end
      end)
end

@defsampler s m::Normal (μ, σ) μ .+ σ.*randn(s.rng, s.N)

z = Normal(1.0, 3.0)
y = Normal(z, 2.0)
x = Normal(z, y)

samples = Sample(5000)(x, nothing)

μ = sum(samples)/length(samples)
σ = sqrt( sum( (samples .- μ).^2 ) / length(samples) )

println("Sample μ/σ: $μ, $σ")
