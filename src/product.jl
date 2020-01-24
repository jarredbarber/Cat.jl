# Cartesian categories
quote
struct Product{N, A, T} <: Arrow{A, T}
    factors::NTuple{N, Arrow{A, C} where C}
    # TODO: checks
    Product(arrows...) = begin
        N = length(arrows)
        if N == 0
            # TODO: how to best define this?
            Identity{Nothing}()
        else
            src = Nothing
            T = []
            # This is some weird logic to let you
            # take products where some arrow have source A and
            # some have Nothing.  This is done by replacing each
            # arrow α :: Nothing --> T with α' = α o Terminal{A}
            # This is pretty important to make things work nicely with
            # constants.
            for a in arrows
                push!(T, target(a))
                s = source(a)
                if s != Nothing
                    if src == Nothing
                        src = s
                    elseif src != s
                        error("Incompatible source types $(src), $s")
                    end
                end
            end

            if src != Nothing
                arrows = tuple([source(a) == Nothing ? Cat.compose(a, Terminal{src}()) : a for a in arrows]...)
            end

            new{N, src, Tuple{T...}}(arrows)
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

Base.getindex(m::Arrow{A, B}, k::Int64) where {A, B<:Tuple} = begin
    Cat.compose(Proj{B, B.parameters[k]}(k), m)
end
end # quote
