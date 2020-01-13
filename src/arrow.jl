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

abstract type Identity{A} <: Arrow{A, A}
end

parent_category(a::Type{<:Arrow}) = __module__

function compose
end

function lift
end

"Defines composition rules making m1 and m2 inverses (an isomorphism pair)."
macro inverse(category, m1, m2)
    esc(quote
        function compose(g::$m1, f::$m2)
            A, B = composition_obj(g, f)
            @assert A == B
            $category.Identity{A}()
        end
        compose(g::$m2, f::$m1) = Cat.compose(f, g)

        function compose(g::$m1, f::$category.Composed{T2, T1, S2, S1}) where {T1,S2,S1, T2 <: $m2}
            A, B = composition_obj(g, f.g)
            @assert A == B
            f.f
        end

        function compose(g::$m2, f::$category.Composed{T2, T1, S2, S1}) where {T1,S2,S1, T2 <: $m1}
            A, B = composition_obj(g, f.g)
            @assert A == B
            f.f
        end
    end)
end

"Define a new category, which manifests itself as a module with some populated types."
macro category(arrow_type, flags...)
    e =
        quote
            module $arrow_type
            using Cat
            abstract type Arrow{A, B} <: Cat.Arrow{A, B}; end
            struct Identity{A} <: Cat.Identity{A}; end

            Cat.parent_category(a::Type{<:Arrow}) = __module__

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
