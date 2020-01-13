# 🐱.jl - Cartesian Closed Categories

Library for building non-macro DSLs with multiple interpretaions ala [Compiling To Categories](http://conal.net/papers/compiling-to-categories)

Example:

```julia
using Cat

# New category
@category Z

struct Next <: Z.Arrow{Nothing, Nothing}
   Next(f) = compose(new(), f)
end

zero = Z.Identity{Nothing}()
one = Next(zero)
two = Next(one)

# Below this line is TBD

struct Prev <: Z.Arrow{Nothing, Nothing}
   Prev(f) = compose(new(), f)
end
   
@inverse Next Prev

one = Prev(two)
zero = Prev(one) # Yields Z.Identity{Nothing}()

```
