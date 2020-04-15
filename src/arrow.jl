# Base category on Julia types

abstract type Arrow{A, B}; end

source(::Arrow{A,B}) where {A, B} = A
source(::Type{Arrow{A,B}}) where {A, B} = A
target(::Arrow{A,B}) where {A, B} = B
target(::Type{Arrow{A,B}}) where {A, B} = B

export source, target, @arrow, @alias, typestr

"Compute the source and target of the composed morphism g o f, or error if they are not composable."
function composition_obj(g::Arrow, f::Arrow)
    A = source(f)
    Bf = target(f)
    Bg = source(g)
    C = target(g)

    if Bf <: Bg
        return (A, C) # Composition will be an Arrow{A, C}
    else
        error("Cannot compose ($A~>$Bf) to ($Bg~>$C)")
    end
end

parent_category(a::Type{<:Arrow}) = __module__

function compose
end

function lift
end

function typestr(a::Arrow)
    "$(typeof(a).name) :: $(source(a)) ~> $(target(a))"
end

"
```
@arrow C Name{T1, T2} :: A --> B mutable struct
    p1::T1
    p2::T2
end
```

or

```
@arrow C Adder{T<:Number} :: T --> T
```
"
macro arrow(category, type_expr, structure=:())
    @capture(type_expr, name_ :: src_ --> tgt_)
    # TODO: Walk src, tgt and convert, e.g., (A, B) to Tuple{A, B}
    if isexpr(src, :tuple)
        src = :(Tuple{$(src.args...)})
    end
    has_type_params = @capture(name, sname_{targs__})
    new_expr = has_type_params ? :(new{$(targs...)}()) : :(new())
    where_expr = has_type_params ? :(where{$(targs...)}) : :()
    # TODO: Parse out structure fields and inner constructors
    #       then auto-composify inner constructors
    esc(quote
        mutable struct $name <: $category.Arrow{$src, $tgt}
           $(structure.args...)
           $name(args...) = compose($new_expr, args...)
        end
        end)
end

"Aliases an arrow constructor to a function"
macro alias(category, arrow_type, alias, arity)
    # TODO: automatically determine arity
    exprs = []
    args = convert(Vector{Any}, [Symbol("arg$k") for k in 1:arity])
    aargs = [:($a::$category.Arrow) for a in args]

    for q=1:(2^arity-1)
        pattern = q
        vargs = copy(args)
        k = 1
        while pattern > 0
            if pattern & 1 == 1
                vargs[k] = aargs[k]
            end
            pattern >>= 1
            k += 1
        end
        push!(exprs, :($alias($(vargs...)) = $arrow_type($(args...))))
    end

    esc(quote
            $(exprs...)
        end)
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
    product_code = include("$(@__DIR__)/product.jl")
    e =
        quote
            module $arrow_type
            export Arrow, Identity, Terminal, Composed, Constant
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
                if isnothing(fs) || isempty(fs)
                    g
                else
                    fs = lift.(fs)
                    Cat.compose(g, Product(fs...))
                end
            end

            # Handle terminals
            function Cat.compose(g::Terminal{A}, f::Arrow{B,A}) where {A, B}
                Terminal{B}()
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
