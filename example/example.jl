using Cat
@category Z

struct Next <: Z.Arrow{Nothing, Nothing}
end

struct Prev <: Z.Arrow{Nothing, Nothing}
end

Next(f) = compose(Next(), f)
Prev(f) = compose(Prev(), f)

@inverse Z Next Prev

println(Next(Prev()))
