# Cartesian categories
quote
struct Product{N, A, T} <: Arrow{A, T}
    factors::NTuple{N, Arrow{A, C} where C}
    # TODO: checks
    Product(arrows...) = begin
        N = length(arrows)
        if N == 0
            Terminal{A}()
        else
            A = source(arrows[1])
            T = Tuple{[target(a) for a in arrows]...}
            new{N, A, T}(arrows)
        end
    end
end

struct Proj{A<:Tuple, T} <: Arrow{A, T}
    m::Int64
end

function Cat.compose(g::Proj{A, T}, f::Product{N, R, A}) where {A,R,N,T}
    f.factors[g.m]
end

Base.getindex(m::Product{N, A, T}, k::Int64) where {N, A, T} = begin
    if 0 < k <= N
        m.factors[k]
    else
        error("")
    end
end

Base.getindex(m::Arrow{A, B}, k::Int64) where {A, B} = begin
    if 0 < k < length(B)
        Proj{A, B[k]}()
    end
end
end # quote
