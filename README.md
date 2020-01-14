# 🐱.jl - Cartesian Closed Categories

Library for building composible DSLs with multiple interpretaions ala [Compiling To Categories](http://conal.net/papers/compiling-to-categories)

Example:

```julia
using Cat

# New category
@category Z

# "Next is a single morphism in Z (no type parameters) from Nothing -> Nothing"
@morphism Z Next {} {Nothing, Nothing}
@morphism Z Prev {} {Nothing, Nothing}
@inverse Z Next Prev # Make (Next, Prev) an isomorphism pair

# Do some algebra
zero = Z.Identity{Nothing}()
one = Next(zero)
two = Next(one)

Prev(f) = compose(new(), f)

one = Prev(two)
zero = Prev(one) # Yields Z.Identity{Nothing}()

```
