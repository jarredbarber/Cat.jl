# 🐱.jl - Cartesian Closed Categories

Library for building non-macro DSLs with multiple interpretaions ala [Compiling To Categories](http://conal.net/papers/compiling-to-categories)

Example:

```julia
using Cat

# New category
@category Z

struct Next <: Z.Arrow{Nothing, Nothing}
end

Next(f) = compose(new(), f)

zero = Z.Identity{Nothing}()
one = Next(zero)
two = Next(one)

struct Prev <: Z.Arrow{Nothing, Nothing}
end

Prev(f) = compose(new(), f)

@inverse Z Next Prev

one = Prev(two)
zero = Prev(one) # Yields Z.Identity{Nothing}()

```
