# Base category on Julia types

abstract type Arrow{A, B}; end

source(t::Arrow{A,B}) where {A, B} = A
target(t::Arrow{A,B}) where {A, B} = B
function composition_obj(g::Arrow, f::Arrow)
    A = source(f)
    Bf = target(f)
    Bg = source(g)
    C = target(g)

    if Bf == Bg
        return (A, C) # Composition will be an Arrow{A, C}
    else
        error("Cannot compose")
    end
end

function compose
end

function lift
end

abstract type Identity{A} <: Arrow{A, A}
end


macro category(arrow_type, flags...)
    e =
        quote
            module $arrow_type
            using Cat
            abstract type Arrow{A, B} <: Cat.Arrow{A, B}; end
            struct Identity{A} <: Cat.Identity{A}; end

            Cat.compose(a::Arrow{A, B}, b::Identity{A}) where {A,B} = a
            Cat.compose(a::Identity{B}, b::Arrow{A, B}) where {A,B} = b

            "Free composition"
            struct Composed{T2, T1, S2, S1} <: Arrow{S1, S2}
                g::T2
                f::T1
            end
            # Force associativity
            Cat.compose(b::Composed, a::Arrow) = compose(b.g, compose(b.f, a))
            # General composition
            function Cat.compose(g::T2, f::T1) where {T1 <: Arrow, T2 <: Arrow}
                A, C = composition_obj(g, f)
                Composed{T2, T1, C, A}(g, f)
            end

            struct Constant{A} <: Arrow{Nothing, A}
                val::A
            end

            "Lifts values of type A to arrows Nothing~>A while leaving arrows alone"
            Cat.lift(a::Arrow) = a
            Cat.lift(a) = Constant(a)
        end
end
# This is necessary to allow defining modules
esc(Expr(:toplevel, e.args...))
end
