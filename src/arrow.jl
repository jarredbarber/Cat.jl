# Base category on Julia types

abstract type Arrow{A, B}; end

source(t::Arrow{A,B}) where {A, B} = A
target(t::Arrow{A,B}) where {A, B} = B

export source, target

"Compute the source and target of the composed morphism g o f, or error if they are not composable."
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

macro morphism(category, name, in_tp, out_tp)
    in_tp = in_tp.args
    out_tp = out_tp.args
    if isempty(in_tp)
        esc(quote
            struct $name <: $category.Arrow{$(out_tp...)}
            end
            $name(f...) = compose($name(), f...)
            end)
    else
        esc(quote
            struct $name{$(in_tp...)} <: $category.Arrow{$(out_tp...)}
            end
            $name{$(in_tp...)}(f...) = compose($name{$(in_tp...)}(), f...)
            end)
    end
end

"Defines composition rules making m1 and m2 inverses (an isomorphism pair)."
macro inverse(category, m1, m2)
    # TODO: auto-infer category
    esc(quote
        function compose(g::$m1, f::$m2)
            A, B = composition_obj(g, f)
            @assert A == B
            $category.Identity{A}()
        end
        compose(g::$m2, f::$m1) = Cat.compose(f, g)

        function compose(g::$m1, f::$category.Composed{<:$m2}) 
            A, B = composition_obj(g, f.g)
            @assert A == B
            f.f
        end

        function compose(g::$m2, f::$category.Composed{<:$m1})
            A, B = composition_obj(g, f.g)
            @assert A == B
            f.f
        end
    end)
end

"Define a new category, which manifests itself as a module with some populated types."
macro category(arrow_type, flags...)
    product_code = include("../src/product.jl")
    e =
        quote
            module $arrow_type
            using Cat
            abstract type Arrow{A, B} <: Cat.Arrow{A, B}; end
            struct Identity{A} <: Arrow{A, A}; end
            struct Terminal{A} <: Arrow{A, Nothing}; end

            Cat.parent_category(a::Type{<:Arrow}) = __module__

            Cat.compose(a::Arrow{A, B}, b::Identity{A}) where {A,B} = a
            Cat.compose(a::Identity{B}, b::Arrow{A, B}) where {A,B} = b

            "Free composition"
            struct Composed{T2, T1, S2, S1} <: Arrow{S1, S2}
                g::T2
                f::T1
            end

            $(product_code.args...)
            # Force associativity
            Cat.compose(b::Composed, a::Arrow) = compose(b.g, compose(b.f, a))

            # Handle tuples automatically
            function Cat.compose(g::T2, fs...) where {T2 <: Arrow}
                fs = lift.(fs)
                Cat.compose(g, Product(fs...))
            end

            # General composition
            function Cat.compose(g::T2, f::T1) where {T1 <: Arrow, T2 <: Arrow}
                A, C = composition_obj(g, f)
                Composed{T2, T1, C, A}(g, f)
            end

            struct Constant{A} <: Arrow{Nothing, A}
                val::A
            end

            "Lifts values of type A to arrows Nothing~>A while leaving arrows alone"
            lift(a::Arrow) = a
            lift(a) = Constant(a)
           end
    end
    # This is necessary to allow defining modules
    esc(Expr(:toplevel, e.args...))
end
