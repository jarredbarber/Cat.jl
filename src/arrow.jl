# Base category on Julia types

abstract type Arrow{A, B}; end

source(t::Arrow{A,B}) where {A, B} = A
target(t::Arrow{A,B}) where {A, B} = B

struct Identity{A} <: Arrow{A, A}
end

struct Initial{A} <: Arrow{Tuple{}, A}
end

struct Terminal{A} <: Arrow{A, Nothing}
end

struct FreeComposition{A,B,C} <: Arrow{A, C}
    g::Arrow{B, C}
    f::Arrow{A, B}
end

# Composition laws
compose(a::Arrow{B, C}, b::Arrow{A, B}) = FreeComposition(a, b)
compose(a::Arrow{A, B}, b::Identity{A}) where {A,B} = a
compose(a::Identity{B}, b::Arrow{A, B}) where {A,B} = b
compose(a::Arrow{B, C}, b::FreeComposition{A, T, B}) where {A,B} = compose(compose(a, b.f), b.g)
compose(t::Terminal{B}, a::Arrow{A, B}) = Terminal{A}

struct Constant{A} <: Arrow{Nothing, A}
    val::A
end

"Lifts values of type A to arrows Nothing~>A while leaving arrows alone"
lift_value(a::Arrow) = a
lift_value(a) = Constant(a)
